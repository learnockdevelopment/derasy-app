import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/admission_models.dart';
import '../../models/student_models.dart';
import '../../services/admission_service.dart';
import '../../services/students_service.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../widgets/hero_section_widget.dart';
import '../../widgets/global_chatbot_widget.dart';
import '../../services/user_storage_service.dart';
import '../../widgets/student_selection_sheet.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({Key? key, this.childId, this.child}) : super(key: key);

  final String? childId;
  final Student? child;

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  List<Application> _allApplications = [];
  List<Application> _filteredApplications = [];
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  final TextEditingController _searchController = TextEditingController();
  int _totalStudents = 0;
  
  String? get _filterChildId => widget.childId ?? widget.child?.id;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterApplications);
    _loadUserData();
    _loadStudentsCount();
    _loadApplications();
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

  Future<void> _loadStudentsCount() async {
    try {
      final response = await StudentsService.getRelatedChildren();
      if (mounted) {
        setState(() {
          _totalStudents = response.success ? response.students.length : 0;
        });
      }
    } catch (e) {
      print('📋 [APPLICATIONS] Error loading students count: $e');
      if (mounted) {
        setState(() {
          _totalStudents = 0;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when returning to this page
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AdmissionService.getApplications();
      if (mounted) {
        // Filter by child ID if provided
        List<Application> filtered = response.applications;
        if (_filterChildId != null && _filterChildId!.isNotEmpty) {
          filtered = response.applications.where((app) {
            return app.child.id == _filterChildId;
          }).toList();
        }
        
        setState(() {
          _allApplications = filtered;
          _filterApplications();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      String errorMessage = 'Failed to load applications. Please try again.';
      if (e is AdmissionException) {
        errorMessage = e.message;
      }

      Get.snackbar(
        'error'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _filterApplications() {
    if (!mounted) return;
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredApplications = _allApplications;
      } else {
        _filteredApplications = _allApplications.where((app) {
          return app.school.name.toLowerCase().contains(query) ||
              app.child.fullName.toLowerCase().contains(query) ||
              _getStatusLabel(app.status).toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Color _getStatusColor(String status) {
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
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
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
        return 'draft'.tr;
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
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
        return Icons.edit_note_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadApplications,
        color: AppColors.primaryBlue,
        child: CustomScrollView(
          slivers: [
            // Hero Section - only show when showing all applications (not filtered by child)
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
                    actionButtonText: 'add_application'.tr,
                    actionButtonIcon: IconlyBroken.plus,
                    onActionTap: () {
                      if (_totalStudents == 0) {
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
                    isButtonDisabled: _totalStudents == 0,
                    disabledMessage: 'add_student_first_to_apply'.tr,
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
                    onPressed: _loadApplications,
                  ),
                ],
              ),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            
            // Applications List
            _isLoading
                ? SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: ShimmerCard(
                              height: 180.h,
                              borderRadius: 24.r,
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
    final statusColor = _getStatusColor(application.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(
          AppRoutes.applicationDetails,
          arguments: {'applicationId': application.id},
        ),
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                statusColor.withOpacity(0.02),
              ],
            ),
            border: Border.all(
              color: statusColor.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Status Icon and Badge
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          statusColor,
                          statusColor.withOpacity(0.75),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getStatusIcon(application.status),
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.school.name,
                          style: AppFonts.h4.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getStatusLabel(application.status),
                            style: AppFonts.bodySmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    IconlyBroken.arrow_right_2,
                    color: statusColor.withOpacity(0.5),
                    size: 24.sp,
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Divider
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      statusColor.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Student Info
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      IconlyBroken.profile,
                      size: 18.sp,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      application.child.fullName,
                      style: AppFonts.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // Footer - Payment and Date
              Row(
                children: [
                  if (application.payment != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: (application.payment!.isPaid
                                ? AppColors.success
                                : AppColors.warning)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: (application.payment!.isPaid
                                  ? AppColors.success
                                  : AppColors.warning)
                              .withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            application.payment!.isPaid
                                ? Icons.check_circle_rounded
                                : Icons.payment_rounded,
                            size: 16.sp,
                            color: application.payment!.isPaid
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            application.payment!.isPaid
                                ? 'paid'.tr
                                : 'unpaid'.tr,
                            style: AppFonts.bodySmall.copyWith(
                              color: application.payment!.isPaid
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconlyBroken.calendar,
                            size: 16.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            _formatDate(application.createdAt),
                            style: AppFonts.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    return '${date.day}/${date.month}/${date.year}';
  }
}
