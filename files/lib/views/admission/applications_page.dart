import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
                  expandedHeight: Responsive.h(140),
                  floating: false,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 0,
                  collapsedHeight: Responsive.h(140),
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
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: Responsive.sp(24)),
                    onPressed: () => Get.back(),
                  ),
                  title: Text(
                    widget.child != null
                        ? 'child_applications'.tr.replaceAll('{name}', widget.child!.fullName)
                        : 'applications'.tr,
                    style: AppFonts.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.sp(18),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white, size: Responsive.sp(24)),
                      onPressed: _onRefresh,
                    ),
                  ],
                ),
              
              if (controller.isTakingLong && isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: Responsive.symmetric(horizontal: 20, vertical: 12),
                    child: Container(
                      padding: Responsive.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Responsive.r(12)),
                        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: Responsive.sp(20)),
                          SizedBox(width: Responsive.w(12)),
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
                    padding: Responsive.symmetric(horizontal: 20, vertical: 12),
                    child: InkWell(
                      onTap: () => controller.refreshAll(),
                      child: Container(
                        padding: Responsive.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Responsive.r(12)),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded, color: AppColors.error, size: Responsive.sp(20)),
                            SizedBox(width: Responsive.w(8)),
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

              SliverToBoxAdapter(child: SizedBox(height: Responsive.h(20))),
              
              // Applications List
              isLoading && _filteredApplications.isEmpty
                  ? SliverPadding(
                      padding: Responsive.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Padding(
                              padding: Responsive.only(bottom: 16),
                              child: ShimmerCard(
                                height: Responsive.h(140),
                                borderRadius: Responsive.r(16),
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
                                  padding: Responsive.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    IconlyBroken.document,
                                    size: Responsive.sp(64),
                                    color: AppColors.primaryBlue.withOpacity(0.6),
                                  ),
                                ),
                                SizedBox(height: Responsive.h(24)),
                                Text(
                                  'no_applications_found'.tr,
                                  style: AppFonts.h3.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: Responsive.sp(20),
                                  ),
                                ),
                                SizedBox(height: Responsive.h(12)),
                                Text(
                                  'applications_will_appear_here'.tr,
                                  style: AppFonts.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: Responsive.sp(14),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: Responsive.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Padding(
                                  padding: Responsive.only(bottom: 16),
                                  child: _buildApplicationCard(_filteredApplications[index]),
                                );
                              },
                              childCount: _filteredApplications.length,
                            ),
                          ),
                        ),
              SliverToBoxAdapter(child: SizedBox(height: Responsive.h(100))),
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
        borderRadius: BorderRadius.circular(Responsive.r(20)),
        child: Container(
          padding: Responsive.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.r(20)),
            border: Border.all(
              color: statusColor.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                        padding: Responsive.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Responsive.r(12)),
                        ),
                        child: Icon(
                          _getStatusIcon(application.status, isPaid),
                          color: statusColor,
                          size: Responsive.sp(18),
                        ),
                      ),
                      SizedBox(width: Responsive.w(12)),
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
                              margin: Responsive.only(top: 4),
                              padding: Responsive.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(Responsive.r(4)),
                              ),
                              child: Text(
                                application.applicationType!.tr.toUpperCase(),
                                style: AppFonts.bodySmall.copyWith(
                                  color: AppColors.primaryBlue,
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
                    padding: Responsive.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(Responsive.r(10)),
                    ),
                    child: Text(
                      _getStatusLabel(application.status, isPaid),
                      style: AppFonts.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.sp(11),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: Responsive.h(16)),
              
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
                            fontSize: Responsive.sp(16),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (application.school.address != null) ...[
                          SizedBox(height: Responsive.h(4)),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: Responsive.sp(12), color: AppColors.textSecondary),
                              SizedBox(width: Responsive.w(4)),
                              Expanded(
                                child: Text(
                                  application.school.address!,
                                  style: AppFonts.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: Responsive.sp(11),
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
                    size: Responsive.sp(18),
                  ),
                ],
              ),
              
              Padding(
                padding: Responsive.symmetric(vertical: 12),
                child: Divider(color: AppColors.grey200, height: 1),
              ),

              // Student details
              Row(
                children: [
                  Container(
                    padding: Responsive.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconlyBroken.profile,
                      size: Responsive.sp(14),
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  SizedBox(width: Responsive.w(10)),
                  Expanded(
                    child: Text(
                      displayName,
                      style: AppFonts.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: Responsive.sp(14),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (application.child.gender != null)
                    Container(
                      padding: Responsive.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: application.child.gender?.toLowerCase() == 'male'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Responsive.r(8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            application.child.gender?.toLowerCase() == 'male'
                                ? Icons.male
                                : Icons.female,
                            size: Responsive.sp(12),
                            color: application.child.gender?.toLowerCase() == 'male'
                                ? Colors.blue
                                : Colors.pink,
                          ),
                          SizedBox(width: Responsive.w(4)),
                          Text(
                            application.child.gender?.toLowerCase() == 'male'
                                ? 'male'.tr
                                : 'female'.tr,
                            style: AppFonts.bodySmall.copyWith(
                              color: application.child.gender?.toLowerCase() == 'male'
                                  ? Colors.blue
                                  : Colors.pink,
                              fontSize: Responsive.sp(10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: Responsive.h(16)),
              
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
                  SizedBox(width: 10.w),
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
