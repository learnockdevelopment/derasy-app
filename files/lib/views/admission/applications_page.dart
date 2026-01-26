import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/admission_models.dart';
import '../../models/student_models.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../widgets/hero_section_widget.dart';
import '../../widgets/global_chatbot_widget.dart';
import '../../services/user_storage_service.dart';
import '../../core/controllers/dashboard_controller.dart';
import '../../widgets/student_selection_sheet.dart';
import '../../widgets/horizontal_swipe_detector.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({Key? key, this.childId, this.child}) : super(key: key);

  final String? childId;
  final Student? child;

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  List<Application> _filteredApplications = [];
  Map<String, dynamic>? _userData;
  final TextEditingController _searchController = TextEditingController();
  
  String? get _filterChildId => widget.childId ?? widget.child?.id;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterApplications);
    _loadUserData();
    final controller = DashboardController.to;
    ever(controller.allApplications, (_) => _filterApplications());
    _filterApplications();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterApplications); 
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userData = await UserStorageService.getUserData();
    if (mounted) {
      setState(() {
        _userData = userData;
      });
    }
  }

  Future<void> _onRefresh() async {
    await DashboardController.to.refreshAll();
    _filterApplications();
  }

  void _filterApplications() {
    if (!mounted) return;
    final controller = DashboardController.to;
    final query = _searchController.text.toLowerCase();
    
    // Filter applications from the controller
    List<Application> filtered = controller.allApplications;
    if (_filterChildId != null && _filterChildId!.isNotEmpty) {
      filtered = filtered.where((app) => app.child.id == _filterChildId).toList();
    }

    setState(() {
      if (query.isEmpty) {
        _filteredApplications = filtered;
      } else {
        _filteredApplications = filtered.where((app) {
          final isPaid = app.payment?.isPaid ?? false;
          return app.school.name.toLowerCase().contains(query) ||
              app.child.fullName.toLowerCase().contains(query) ||
              _getStatusLabel(app.status, isPaid).toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Color _getStatusColor(String status, bool isPaid) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'under_review':
        return AppColors.blue1;
      case 'recommended':
        return const Color(0xFF6366F1);
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'draft':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status, bool isPaid) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'pending'.tr;
      case 'under_review':
        return 'under_review'.tr;
      case 'recommended':
        return 'recommended'.tr;
      case 'accepted':
        return 'accepted'.tr;
      case 'rejected':
        return 'rejected'.tr;
      case 'draft':
        return 'pending'.tr;
      default:
        return status.tr;
    }
  }

  IconData _getStatusIcon(String status, bool isPaid) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'under_review':
        return Icons.visibility_rounded;
      case 'recommended':
        return Icons.star_rounded;
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'draft':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _filterChildId == null 
        ? HorizontalSwipeDetector(
          onSwipeRight: () {
            Get.offNamed(AppRoutes.myStudents);
          },
          onSwipeLeft: () {
            Get.offNamed(AppRoutes.storeProducts);
          },
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.blue1,
          final controller = DashboardController.to;
          final isLoading = controller.isLoading;
          return _buildBodyContent(controller, isLoading);
        }),
      ),
    ) 
    : RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.blue1,
        child: Obx(() {
          final controller = DashboardController.to;
          final isLoading = controller.isLoading;
          return _buildBodyContent(controller, isLoading);
        }),
      ),
      ),
      bottomNavigationBar: _filterChildId == null
          ? BottomNavBarWidget(
              currentIndex: _getCurrentIndex(),
              onTap: (index) {},
            )
          : null,
      floatingActionButton: _filterChildId == null
          ? DraggableChatbotWidget()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildApplicationCard(Application application) {
    final isPaid = application.payment?.isPaid ?? false;
    final statusColor = _getStatusColor(application.status, isPaid);
    final displayName = application.child.arabicFullName ?? application.child.fullName;
    final hasConfirmedInterview = application.interview?.date != null;
    final hasPreferredSlots = application.preferredInterviewSlots.isNotEmpty;
    final shortId = application.id.length > 8 
        ? application.id.substring(application.id.length - 8).toUpperCase()
        : application.id.toUpperCase();
    
    DateTime? interviewDate;
    String? interviewTime;
    
    if (hasConfirmedInterview) {
      interviewDate = application.interview!.date;
      interviewTime = _formatTimeDisplay(application.interview!.time);
    } else if (hasPreferredSlots) {
      final slot = application.preferredInterviewSlots.first;
      interviewDate = slot.date;
      interviewTime = "${'from_time'.tr} ${slot.timeRange.from} ${'to_time'.tr} ${slot.timeRange.to}";
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(
          AppRoutes.applicationDetails,
          arguments: {'applicationId': application.id},
        ),
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        child: Container(
          padding: Responsive.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            border: Border.all(
              color: statusColor.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Icon and ID / Type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: Responsive.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Responsive.r(10)),
                        ),
                        child: Icon(
                          _getStatusIcon(application.status, isPaid),
                          color: statusColor,
                          size: Responsive.sp(16),
                        ),
                      ),
                      SizedBox(width: Responsive.w(8)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'application_id_short'.tr}: #$shortId',
                            style: AppFonts.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.sp(10),
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (application.applicationType != null)
                            Container(
                              margin: Responsive.only(top: 2),
                              padding: Responsive.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.blue1.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(Responsive.r(4)),
                              ),
                              child: Text(
                                application.applicationType!.tr.toUpperCase(),
                                style: AppFonts.bodySmall.copyWith(
                                  color: AppColors.blue1,
                                  fontSize: Responsive.sp(8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: Responsive.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(Responsive.r(8)),
                    ),
                    child: Text(
                      _getStatusLabel(application.status, isPaid),
                      style: AppFonts.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.sp(10),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: Responsive.h(10)),
              
              // School and Child Info Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.school.name,
                          style: AppFonts.h4.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: Responsive.sp(15),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (application.school.address != null) ...[
                          SizedBox(height: Responsive.h(2)),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: Responsive.sp(12), color: AppColors.textSecondary),
                              SizedBox(width: Responsive.w(2)),
                              Expanded(
                                child: Text(
                                  application.school.address!,
                                  style: AppFonts.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: Responsive.sp(10),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    IconlyBroken.arrow_right_2,
                    color: AppColors.grey400,
                    size: Responsive.sp(16),
                  ),
                ],
              ),
              
              Padding(
                padding: Responsive.symmetric(vertical: 8),
                child: Divider(color: AppColors.grey200, height: 1),
              ),

              // Student details
              Row(
                children: [
                  Container(
                    padding: Responsive.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconlyBroken.profile,
                      size: Responsive.sp(12),
                      color: AppColors.blue1,
                    ),
                  ),
                  SizedBox(width: Responsive.w(8)),
                  Expanded(
                    child: Text(
                      displayName,
                      style: AppFonts.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: Responsive.sp(13),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (application.child.gender != null)
                    Container(
                      padding: Responsive.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: application.child.gender?.toLowerCase() == 'male'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Responsive.r(6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            application.child.gender?.toLowerCase() == 'male'
                                ? Icons.male
                                : Icons.female,
                            size: Responsive.sp(10),
                            color: application.child.gender?.toLowerCase() == 'male'
                                ? Colors.blue
                                : Colors.pink,
                          ),
                          SizedBox(width: Responsive.w(2)),
                          Text(
                            application.child.gender?.toLowerCase() == 'male'
                                ? 'male'.tr
                                : 'female'.tr,
                            style: AppFonts.bodySmall.copyWith(
                              color: application.child.gender?.toLowerCase() == 'male'
                                  ? Colors.blue
                                  : Colors.pink,
                              fontSize: Responsive.sp(9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: Responsive.h(10)),
              
              // Footer - Dates and Payment
              Row(
                children: [
                  // Submitted Date
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.send_rounded,
                      label: 'submitted_date'.tr,
                      value: _formatDate(application.submittedAt ?? application.createdAt),
                      color: AppColors.blue1,
                    ),
                  ),
                  SizedBox(width: Responsive.w(8)),
                  // Interview or Payment info
                  Expanded(
                    child: interviewDate != null
                        ? _buildInfoChip(
                            icon: Icons.event_available_rounded,
                            label: hasConfirmedInterview ? 'interview_scheduled'.tr : 'interview_date'.tr,
                            value: '${_formatDate(interviewDate)}\n${interviewTime ?? ""}',
                            color: AppColors.warning,
                          )
                        : application.payment != null
                            ? _buildInfoChip(
                                icon: application.payment!.isPaid
                                    ? Icons.check_circle_rounded
                                    : Icons.hourglass_empty_rounded,
                                label: application.payment!.isPaid ? 'paid'.tr : 'pending'.tr,
                                value: '${application.payment!.amount} ${'egp'.tr}',
                                color: application.payment!.isPaid
                                    ? AppColors.success
                                    : AppColors.warning,
                              )
                            : SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: Responsive.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Responsive.r(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: Responsive.sp(10), color: color),
              SizedBox(width: Responsive.w(4)),
              Expanded(
                child: Text(
                  label,
                  style: AppFonts.bodySmall.copyWith(
                    color: color,
                    fontSize: Responsive.sp(9),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(2)),
          Text(
            value,
            style: AppFonts.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: Responsive.sp(11),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex() {
    final route = Get.currentRoute;
    if (route == AppRoutes.home) return 0;
    if (route == AppRoutes.myStudents) return 1;
    if (route == AppRoutes.applications) return 2;
    if (route == AppRoutes.storeProducts || route == AppRoutes.store) return 3;
    return 2; // Default to Applications
  }

  String _formatDate(DateTime date) {
    final monthKeys = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    return '${date.day} ${monthKeys[date.month - 1].tr} ${date.year}';
  }

  String _formatTimeDisplay(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    
    // Check if it's a range like "HH:mm - HH:mm" or "HH:mm-HH:mm"
    final rangeMatch = RegExp(r"(\d{1,2}:\d{2})\s*[-–—]\s*(\d{1,2}:\d{2})").firstMatch(timeStr);
    if (rangeMatch != null) {
      final from = rangeMatch.group(1);
      final to = rangeMatch.group(2);
      return "${'from_time'.tr} $from ${'to_time'.tr} $to";
    }
    
    return timeStr;
  }
}

