import 'package:get/get.dart';
import '../../models/bus_line_models.dart';
import '../../services/bus_service.dart';
import '../../services/attendance_service.dart';
import '../../services/clinic_records_service.dart';
import '../../services/chat_service.dart';
import '../../services/user_storage_service.dart';
import '../../services/schools_service.dart';
import '../../models/student_models.dart';
import '../../models/bus_models.dart';
import '../../models/chat_models.dart';
import '../../models/class_teacher_models.dart';
import '../../services/grades_service.dart';

class FollowUpController extends GetxController {
  final Student child;
  
  FollowUpController({required this.child});
 
  final String currentUserId = UserStorageService.getCurrentUser()?.id ?? '';

  // Data
  final bus = Rxn<Bus>();
  final attendanceRecords = <AttendanceRecord>[].obs;
  final clinicRecords = <ClinicRecord>[].obs;
  final grades = <Grade>[].obs; // Deprecated, remove later if unused
  final chatMessages = <ChatMessage>[].obs;
  final activeConversation = Rxn<Conversation>();
  final busLines = <BusLine>[].obs;
  final activeLine = Rxn<BusLine>();
  final classTeachers = <ClassTeacher>[].obs;

  // Loading States
  final isLoadingBus = false.obs;
  final isLoadingAttendance = false.obs;
  final isLoadingClinic = false.obs;
  final isLoadingGrades = false.obs; // Deprecated
  final isLoadingChat = false.obs;
  final isSendingMessage = false.obs;
  final isLoadingLines = false.obs;
  final isLoadingTeachers = false.obs;

  // Chat Context
  final selectedParticipantId = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  Future<void> loadAllData() async {
    // Load critical data first
    await Future.wait([
      loadAttendance(),
      // Bus and Clinic can be loaded on demand or in background, but we'll keep them here for now
      // loadBusInfo(), 
      loadClinicRecords(),
    ]);
    // Try to load bus info in background
    loadBusInfo();
  }

  Future<void> loadBusDataIfNeeded() async {
    if (bus.value == null && !isLoadingBus.value) {
      await loadBusInfo();
    }
  }

  Future<void> loadBusInfo() async {
    if (child.schoolId.id.isEmpty) return;
    try {
      isLoadingBus.value = true;
      // Fetch all buses for the school
      final response = await BusService.getBuses(child.schoolId.id);
      print('🚌 [FOLLOW UP] Bus Response: ${response.buses.length} buses found');
      
      Bus? foundBus;
      
      // First pass: check if assignedStudents are already populated in the list response
      for (var b in response.buses) {
        if (b.assignedStudents.isNotEmpty && b.assignedStudents.any((s) => s.student?.id == child.id)) {
          foundBus = b;
          break;
        }
      }

      // Second pass: if not found, fetch details (fallback)
      if (foundBus == null) {
        for (var b in response.buses) {
          try {
            final details = await BusService.getBusDetails(child.schoolId.id, b.id);
             if (details.assignedStudents.any((s) => s.student?.id == child.id)) {
              foundBus = details;
              break;
            }
          } catch (e) {
            // Ignore error for individual bus detail fetch and continue
            print('🚌 [FOLLOW UP] Error fetching details for bus ${b.id}: $e');
          }
        }
      }

      if (foundBus != null) {
        bus.value = foundBus;
        // After finding the bus, load its lines to see progress
        await loadBusLines();
      }
      
    } catch (e) {
      print('🚌 [FOLLOW UP] Error loading bus: $e');
    } finally {
      isLoadingBus.value = false;
    }
  }

  final routes = <dynamic>[].obs;
  final recentLines = <BusLine>[].obs;

  Future<void> loadBusLines() async {
    if (bus.value == null) return;

    try {
      isLoadingLines.value = true;

      // 1. Fetch Active Line (In Progress)
      final activeLinesList = await BusService.getLines(
        child.schoolId.id,
        bus.value!.id,
        status: 'in_progress',
      );
      
      if (activeLinesList.isNotEmpty) {
        // Fetch details to get stations/students
         final lineDetails = await BusService.getLine(
          child.schoolId.id,
          bus.value!.id,
          activeLinesList.first.id,
        );
        activeLine.value = lineDetails;
      } else {
        activeLine.value = null;
      }

      // 2. Fetch Recent Lines (Completed/History)
      // We can fetch all and filter or pagination. For now fetch standard lines.
      final allLines = await BusService.getLines(
        child.schoolId.id,
        bus.value!.id,
      );
      
      // Filter for completed/cancelled and sort by date desc
      final history = allLines
          .where((l) => l.status == 'completed' || l.status == 'cancelled' || l.status == 'active')
          .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      
      recentLines.assignAll(history.take(10).toList()); // Take last 10

      // 3. Fetch Routes
      final r = await BusService.getRoutes(child.schoolId.id, bus.value!.id);
      routes.assignAll(r);

    } catch (e) {
      print('🚌 Error loading bus lines/routes: $e');
    } finally {
      isLoadingLines.value = false;
    }
  }

  Future<void> loadAttendance() async {
    try {
      isLoadingAttendance.value = true;
      final response = await AttendanceService.getAttendanceByChild(child.id);
      if (response.success && response.attendances != null) {
        attendanceRecords.assignAll(response.attendances!);
      }
    } catch (e) {
      print('📅 [FOLLOW UP] Error loading attendance: $e');
    } finally {
      isLoadingAttendance.value = false;
    }
  }

  Future<void> loadClinicRecords() async {
    if (child.schoolId.id.isEmpty) return;
    try {
      isLoadingClinic.value = true;
      final response = await ClinicRecordsService.getStudentClinicRecords(child.schoolId.id, child.id);
      if (response.success) {
        clinicRecords.assignAll(response.clinicRecords);
      }
    } catch (e) {
      print('🏥 [FOLLOW UP] Error loading clinic records: $e');
    } finally {
      isLoadingClinic.value = false;
    }
  }

  Future<void> loadChat() async {
    try {
      isLoadingChat.value = true;
      // Use selected participant or default to school (Admin)
      final participantId = selectedParticipantId.value ?? child.schoolId.id;
      
      final conv = await ChatService.createConversation(participantId);
      activeConversation.value = conv;
      
      final msgs = await ChatService.getMessages(conv.id);
      chatMessages.assignAll(msgs);
    } catch (e) {
      print('💬 [FOLLOW UP] Error loading chat: $e');
    } finally {
      isLoadingChat.value = false;
    }
  }

  Future<void> selectParticipant(String participantId) async {
    if (selectedParticipantId.value == participantId) return;
    selectedParticipantId.value = participantId;
    await loadChat();
  }

  Future<void> loadClassTeachers() async {
    if (child.studentClass.id.isEmpty) return;
    try {
      isLoadingTeachers.value = true;
      final response = await SchoolsService.getClassTeachers(child.schoolId.id, child.studentClass.id);
      classTeachers.assignAll(response.teachers);
    } catch (e) {
      print('👨‍🏫 [FOLLOW UP] Error loading teachers: $e');
    } finally {
      isLoadingTeachers.value = false;
    }
  }

  Future<void> sendMessage(String text) async {
    if (activeConversation.value == null || text.trim().isEmpty) return;
    try {
      isSendingMessage.value = true;
      final msg = await ChatService.sendMessage(activeConversation.value!.id, text);
      chatMessages.add(msg);
    } catch (e) {
      print('💬 [FOLLOW UP] Error sending message: $e');
      Get.snackbar('error'.tr, 'failed_to_send_message'.tr);
    } finally {
      isSendingMessage.value = false;
    }
  }
}
