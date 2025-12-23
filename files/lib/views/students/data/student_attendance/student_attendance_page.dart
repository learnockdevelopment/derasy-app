import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../models/student_models.dart';
import '../../../../services/attendance_service.dart';

class StudentAttendancePage extends StatefulWidget {
  final Student student;
  final String schoolId;

  const StudentAttendancePage({
    Key? key,
    required this.student,
    required this.schoolId,
  }) : super(key: key);

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  bool _isLoading = false;
  List<AttendanceRecord> _attendanceRecords = [];
  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  String _selectedStatus = 'present';
  final _checkInController = TextEditingController();
  final _checkOutController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  @override
  void dispose() {
    _checkInController.dispose();
    _checkOutController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await AttendanceService.getAttendanceByChild(widget.student.id);
      if (response.success) {
        setState(() {
          _attendanceRecords = response.attendances ?? [];
        });
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_attendance'.tr + ': ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final attendance = AttendanceRecord(
        childId: widget.student.id,
        schoolId: widget.schoolId,
        date: _formatDate(_selectedDate),
        status: _selectedStatus,
        checkInTime: _checkInController.text.trim().isNotEmpty
            ? _checkInController.text.trim()
            : null,
        checkOutTime: _checkOutController.text.trim().isNotEmpty
            ? _checkOutController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final response = await AttendanceService.createAttendance(attendance);

      if (response.success) {
        // Reload attendance records
        await _loadAttendance();

        // Clear form
        _checkInController.clear();
        _checkOutController.clear();
        _notesController.clear();
        _selectedStatus = 'present';

        Get.snackbar(
          'success'.tr,
          'attendance_record_created'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_create_attendance'.tr + ': ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          '${'attendance'.tr} - ${widget.student.fullName}',
          style: AppFonts.h4.copyWith(
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Create Attendance Form
          _buildCreateAttendanceForm(),

          // Attendance Records List
          Expanded(
            child: _buildAttendanceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAttendanceForm() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey100.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryBlue,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'create_attendance_record'.tr,
                  style: AppFonts.h5.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Date Selection
            _buildDateField(),

            SizedBox(height: 12.h),

            // Status Selection
            _buildStatusField(),

            SizedBox(height: 12.h),

            // Check-in Time
            _buildTimeField(
              controller: _checkInController,
              label: 'check_in_time_hhmm'.tr,
              icon: Icons.login,
            ),

            SizedBox(height: 12.h),

            // Check-out Time
            _buildTimeField(
              controller: _checkOutController,
              label: 'check_out_time_hhmm'.tr,
              icon: Icons.logout,
            ),

            SizedBox(height: 12.h),

            // Notes
            _buildTextField(
              controller: _notesController,
              label: 'notes_optional'.tr,
              icon: Icons.note,
              maxLines: 2,
            ),

            SizedBox(height: 16.h),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'create_record'.tr,
                        style: AppFonts.buttonMedium.copyWith(
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey300),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20.sp, color: AppColors.grey500),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: AppFonts.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusField() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'status'.tr,
        prefixIcon: Icon(Icons.info, size: 20.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
      items: [
        DropdownMenuItem(value: 'present', child: Text('present'.tr)),
        DropdownMenuItem(value: 'absent', child: Text('absent'.tr)),
        DropdownMenuItem(value: 'late', child: Text('late'.tr)),
      ],
      onChanged: (value) {
        setState(() {
          _selectedStatus = value!;
        });
      },
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        hintText: 'HH:MM',
        hintStyle: AppFonts.bodySmall.copyWith(
          color: AppColors.textSecondary,
          
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        hintStyle: AppFonts.bodySmall.copyWith(
          color: AppColors.textSecondary,
          
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_attendanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64.sp,
              color: AppColors.grey100,
            ),
            SizedBox(height: 16.h),
            Text(
              'no_attendance_records'.tr,
              style: AppFonts.h4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'create_attendance_for_student'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = _attendanceRecords[index];
        return _buildAttendanceCard(record);
      },
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    Color statusColor;
    IconData statusIcon;

    switch (record.status) {
      case 'present':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'absent':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      case 'late':
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = AppColors.grey500;
        statusIcon = Icons.help;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey100.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.date,
                      style: AppFonts.h5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      record.status.toUpperCase(),
                      style: AppFonts.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  record.status.toUpperCase(),
                  style: AppFonts.labelSmall.copyWith(
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (record.checkInTime != null || record.checkOutTime != null) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                if (record.checkInTime != null) ...[
                  Icon(Icons.login,
                      size: 16.sp, color: AppColors.textSecondary),
                  SizedBox(width: 8.w),
                  Text(
                    '${'in'.tr}: ${record.checkInTime}',
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (record.checkInTime != null && record.checkOutTime != null)
                  SizedBox(width: 16.w),
                if (record.checkOutTime != null) ...[
                  Icon(Icons.logout,
                      size: 16.sp, color: AppColors.textSecondary),
                  SizedBox(width: 8.w),
                  Text(
                    '${'out'.tr}: ${record.checkOutTime}',
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                record.notes!,
                style: AppFonts.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}