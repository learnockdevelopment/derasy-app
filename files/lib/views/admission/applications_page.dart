import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import '../../widgets/student_selection_sheet.dart';
import '../../core/controllers/dashboard_controller.dart';

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
    
    // Listen to changes in DashboardController to update local state
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
    if (status.toLowerCase() == 'pending' && isPaid) {
      return AppColors.success;
    }
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'under_review':
        return AppColors.primaryBlue;
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'waitlist':
        return AppColors.primaryPurple;
      case 'draft':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status, bool isPaid) {
    if (status.toLowerCase() == 'pending' && isPaid) {
      return '${'paid'.tr} / ${'pending'.tr}';
    }
    switch (status.toLowerCase()) {
      case 'pending':
        return 'pending'.tr;
      case 'under_review':
        return 'under_review'.tr;
      case 'accepted':
        return 'accepted'.tr;
      case 'rejected':
        return 'rejected'.tr;
      case 'waitlist':
        return 'waitlist'.tr;
      case 'draft':
        return 'pending'.tr;
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status, bool isPaid) {
    if (status.toLowerCase() == 'pending' && isPaid) {
      return Icons.check_circle_outline_rounded;
    }
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'under_review':
        return Icons.visibility_rounded;
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'waitlist':
        return Icons.queue_rounded;
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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primaryBlue,
        child: Obx(() {
          final controller = DashboardController.to;
          final totalStudents = controller.relatedChildren.length;
          final isLoading = controller.isLoading;
          return CustomScrollView(
            slivers: [
              if (_filterChildId == null)
                SliverAppBar(
                  expandedHeight: 140.h,
                  floating: false,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 0,
                  collapsedHeight: 140.h,
                  flexibleSpace: FlexibleSpaceBar(
                    background: HeroSectionWidget(
                      userData: _userData,
                      pageTitle: 'applications'.tr,
                      actionButtonText: isLoading ? null : 'add_application'.tr,
                      actionButtonIcon: isLoading ? null : IconlyBroken.plus,
                      onActionTap: isLoading ? null : () {
                        if (totalStudents == 0) {
                          Get.snackbar(
                            'error'.tr,
                            'no_students_for_application'.tr,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.error,
                            colorText: Colors.white,
                          );
                        } else {
                          // Show bottom sheet to select student first
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const StudentSelectionSheet(),
                          ).then((selectedStudent) {
                            if (selectedStudent != null && selectedStudent is Student) {
                              // Navigate with selected student
                              Get.toNamed(
                                AppRoutes.applyToSchools,
                                arguments: {'child': selectedStudent},
                              );
                            }
                          });
                        }
                      },
                      showGreeting: false,
                      isButtonDisabled: isLoading ? false : totalStudents == 0,
                      disabledMessage: isLoading ? null : 'add_student_first_to_apply'.tr,
                    ),
                  ),
                )
              else
                SliverAppBar(
                  backgroundColor: AppColors.primaryBlue,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
                    onPressed: () => Get.back(),
                  ),
                  title: Text(
                    widget.child != null
                        ? 'child_applications'.tr.replaceAll('{name}', widget.child!.fullName)
                        : 'applications'.tr,
                    style: AppFonts.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white, size: 24.sp),
                      onPressed: _onRefresh,
                    ),
                  ],
                ),
              
              if (controller.isTakingLong && isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 20.sp),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'slow_connection_message'.tr,
                              style: AppFonts.bodySmall.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (controller.isTimeout && !isLoading && _filteredApplications.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: InkWell(
                      onTap: () => controller.refreshAll(),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded, color: AppColors.error, size: 20.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'retry_loading'.tr,
                              style: AppFonts.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              
              // Applications List
              isLoading && _filteredApplications.isEmpty
                  ? SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: ShimmerCard(
                                height: 140.h,
                                borderRadius: 16.r,
                              ),
                            );
                          },
                          childCount: 6,
                        ),
                      ),
                    )
                  : _filteredApplications.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(24.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    IconlyBroken.document,
                                    size: 64.sp,
                                    color: AppColors.primaryBlue.withOpacity(0.6),
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                Text(
                                  'no_applications_found'.tr,
                                  style: AppFonts.h3.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.sp,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'applications_will_appear_here'.tr,
                                  style: AppFonts.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 14.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 16.h),
                                  child: _buildApplicationCard(_filteredApplications[index]),
                                );
                              },
                              childCount: _filteredApplications.length,
                            ),
                          ),
                        ),
              SliverToBoxAdapter(child: SizedBox(height: 100.h)),
            ],
          );
        }),
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
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
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
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          _getStatusIcon(application.status, isPaid),
                          color: statusColor,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'application_id_short'.tr}: #$shortId',
                            style: AppFonts.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.sp,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (application.applicationType != null)
                            Container(
                              margin: EdgeInsets.only(top: 2.h),
                              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                application.applicationType!.tr.toUpperCase(),
                                style: AppFonts.bodySmall.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _getStatusLabel(application.status, isPaid),
                      style: AppFonts.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 10.h),
              
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
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (application.school.address != null) ...[
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 12.sp, color: AppColors.textSecondary),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  application.school.address!,
                                  style: AppFonts.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10.sp,
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
                    size: 16.sp,
                  ),
                ],
              ),
              
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Divider(color: AppColors.grey200, height: 1),
              ),

              // Student details
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconlyBroken.profile,
                      size: 12.sp,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      displayName,
                      style: AppFonts.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (application.child.gender != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: application.child.gender?.toLowerCase() == 'male'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            application.child.gender?.toLowerCase() == 'male'
                                ? Icons.male
                                : Icons.female,
                            size: 10.sp,
                            color: application.child.gender?.toLowerCase() == 'male'
                                ? Colors.blue
                                : Colors.pink,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            application.child.gender?.toLowerCase() == 'male'
                                ? 'male'.tr
                                : 'female'.tr,
                            style: AppFonts.bodySmall.copyWith(
                              color: application.child.gender?.toLowerCase() == 'male'
                                  ? Colors.blue
                                  : Colors.pink,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 10.h),
              
              // Footer - Dates and Payment
              Row(
                children: [
                  // Submitted Date
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.send_rounded,
                      label: 'submitted_date'.tr,
                      value: _formatDate(application.submittedAt ?? application.createdAt),
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  SizedBox(width: 8.w),
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 10.sp, color: color),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  label,
                  style: AppFonts.bodySmall.copyWith(
                    color: color,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: AppFonts.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 11.sp,
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
