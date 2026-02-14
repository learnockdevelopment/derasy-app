import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/admission_models.dart';
import '../../models/student_models.dart';
import '../../core/routes/app_routes.dart';
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
  Map<String, dynamic>? _userData;
  final TextEditingController _searchController = TextEditingController();
  
  String? get _filterChildId => widget.childId ?? widget.child?.id;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadUserData();
  }

  @override
  void dispose() {
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
  }

  // Group applications by batch (submitted together)
  List<List<Application>> _getGroupedApplications() {
    final controller = DashboardController.to;
    final query = _searchController.text.toLowerCase();

    // Filter applications from the controller
    List<Application> filtered = controller.allApplications.toList();
    if (_filterChildId != null && _filterChildId!.isNotEmpty) {
      filtered = filtered.where((app) => app.child.id == _filterChildId).toList();
    }

    // Apply search filter
    if (query.isNotEmpty) {
      filtered = filtered.where((app) {
        final isPaid = app.payment?.isPaid ?? false;
        return app.school.name.toLowerCase().contains(query) ||
            app.child.fullName.toLowerCase().contains(query) ||
            _getStatusLabel(app.status, isPaid).toLowerCase().contains(query);
      }).toList();
    }

    // Group applications by batch
    List<List<Application>> grouped = [];
    Set<String> processedIds = {};

    for (var app in filtered) {
      if (processedIds.contains(app.id)) continue;

      // Find all applications in the same batch
      final submittedAt = app.submittedAt ?? app.createdAt;
      final sameBatch = filtered.where((a) {
        final aSubmittedAt = a.submittedAt ?? a.createdAt;
        final difference = submittedAt.difference(aSubmittedAt).abs();
        return a.child.id == app.child.id && difference.inMinutes <= 5;
      }).toList();

      // Sort by creation time within batch
      sameBatch.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      grouped.add(sameBatch);
      processedIds.addAll(sameBatch.map((a) => a.id));
    }

    // Sort groups by most recent
    grouped.sort((a, b) {
      final aDate = a.first.submittedAt ?? a.first.createdAt;
      final bDate = b.first.submittedAt ?? b.first.createdAt;
      return bDate.compareTo(aDate);
    });

    return grouped;
  }

  // Helper method to get preference order for an application
  int? _getPreferenceOrder(Application application) {
    final controller = DashboardController.to;
    
    // Get all applications for the same child submitted around the same time
    final childApplications = controller.allApplications
        .where((app) => app.child.id == application.child.id)
        .toList();
    
    // Group applications by submission time (within 5 minutes = same batch)
    final submittedAt = application.submittedAt ?? application.createdAt;
    final sameBatchApps = childApplications.where((app) {
      final appSubmittedAt = app.submittedAt ?? app.createdAt;
      final difference = submittedAt.difference(appSubmittedAt).abs();
      return difference.inMinutes <= 5;
    }).toList();
    
    // If there are 2-3 applications in the same batch, assign preference order
    if (sameBatchApps.length >= 2 && sameBatchApps.length <= 3) {
      // Sort by creation time (earliest = 1st preference)
      sameBatchApps.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      // Find the index of current application
      final index = sameBatchApps.indexWhere((app) => app.id == application.id);
      if (index != -1) {
        return index + 1; // 1-based index (1, 2, 3)
      }
    }
    
    return null;
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
      case 'ended':
        return AppColors.grey500;
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
      case 'ended':
        return 'ended'.tr;
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
      case 'ended':
        return Icons.auto_delete_rounded;
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
            if (Responsive.isRTL) {
              Get.offNamed(AppRoutes.storeProducts);
            } else {
              // Swipe to Follow Up (index 2)
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const StudentSelectionSheet(onlySchoolStudents: true),
              ).then((selectedStudent) {
                if (selectedStudent != null && selectedStudent is Student) {
                  Get.toNamed(AppRoutes.followUp, arguments: {'child': selectedStudent});
                }
              });
            }
          },
          onSwipeLeft: () {
            if (Responsive.isRTL) {
               // Swipe to Follow Up (index 2)
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const StudentSelectionSheet(onlySchoolStudents: true),
              ).then((selectedStudent) {
                if (selectedStudent != null && selectedStudent is Student) {
                  Get.toNamed(AppRoutes.followUp, arguments: {'child': selectedStudent});
                }
              });
            } else {
              Get.offNamed(AppRoutes.storeProducts);
            }
          },
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.blue1,
            child: Obx(() {
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
      bottomNavigationBar: _filterChildId == null
          ? const BottomNavBarWidget()
          : null,
      floatingActionButton: Obx(() {
        final controller = DashboardController.to;
        final hasActiveApp = controller.allApplications.any((app) {
          final status = app.status.toLowerCase();
          return status != 'rejected' && status != 'cancelled';
        });

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_filterChildId == null && !hasActiveApp)
              FloatingActionButton(
                onPressed: () {
                  if (controller.relatedChildren.isEmpty) {
                    Get.snackbar(
                      'error'.tr,
                      'no_students_for_application'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.error,
                      colorText: Colors.white,
                    );
                  } else {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const StudentSelectionSheet(),
                    ).then((selectedStudent) {
                      if (selectedStudent != null && selectedStudent is Student) {
                        Get.toNamed(
                          AppRoutes.applyToSchools,
                          arguments: {'child': selectedStudent},
                        );
                      }
                    });
                  }
                },
                backgroundColor: AppColors.blue1,
                tooltip: 'add_application'.tr,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            SizedBox(height: Responsive.h(16)),
            DraggableChatbotWidget(),
          ],
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBodyContent(DashboardController controller, bool isLoading) {
    final groupedApplications = _getGroupedApplications();
    
    return CustomScrollView(
      slivers: [
        // Hero Section
        if (_filterChildId == null)
          SliverAppBar(
            expandedHeight: Responsive.h(Responsive.isTablet || Responsive.isDesktop ? 140 : 80),
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
            toolbarHeight: 0,
            collapsedHeight: Responsive.h(45),
            flexibleSpace: FlexibleSpaceBar(
              background: HeroSectionWidget(
                userData: _userData,
                pageTitle: 'applications'.tr,
                showGreeting: false,
              ),
            ),
          )
        else
          SliverAppBar(
            title: Text('applications'.tr, style: AppFonts.h4.copyWith(fontSize: Responsive.sp(16))),
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            automaticallyImplyLeading: true,
          ),

        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(20))),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search_applications'.tr,
                hintStyle: AppFonts.bodySmall.copyWith(fontSize: Responsive.sp(12), color: AppColors.grey400),
                prefixIcon: const Icon(IconlyLight.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                  borderSide: BorderSide(color: AppColors.grey300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                  borderSide: BorderSide(color: AppColors.grey200),
                ),
                contentPadding: Responsive.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(16))),

        // Content
        if (isLoading && groupedApplications.isEmpty)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (groupedApplications.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconlyLight.document, size: Responsive.sp(64), color: AppColors.grey400),
                  SizedBox(height: Responsive.h(16)),
                  Text(
                    'no_applications_found'.tr,
                    style: AppFonts.bodyLarge.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: Responsive.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final groupedApps = _getGroupedApplications();
                  return Padding(
                    padding: Responsive.only(bottom: 12),
                    child: _buildApplicationGroupCard(groupedApps[index], index + 1),
                  );
                },
                childCount: _getGroupedApplications().length,
              ),
            ),
          ),
        
        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(80))), // Bottom padding
      ],
    );
  }

  Widget _buildApplicationGroupCard(List<Application> applications, int applicationNumber) {
    if (applications.isEmpty) return const SizedBox.shrink();
    
    final firstApp = applications.first;
    final displayName = firstApp.child.arabicFullName ?? firstApp.child.fullName;
    final submittedDate = firstApp.submittedAt ?? firstApp.createdAt;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: Responsive.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Responsive.r(16)),
          border: Border.all(
            color: AppColors.blue1.withOpacity(0.15),
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
            // Header - Application Number and Student Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: Responsive.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.blue1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Responsive.r(10)),
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        color: AppColors.blue1,
                        size: Responsive.sp(16),
                      ),
                    ),
                    SizedBox(width: Responsive.w(8)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'num_application'.tr} #$applicationNumber',
                          style: AppFonts.bodySmall.copyWith(
                            color: AppColors.blue1,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.sp(12),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          displayName,
                          style: AppFonts.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: Responsive.sp(10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: Responsive.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Responsive.r(8)),
                  ),
                  child: Text(
                    '${applications.length} ${'schools'.tr}',
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.blue1,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.sp(10),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: Responsive.h(12)),
            
            // Interview Summary Box (if any school has interview)
            Builder(
              builder: (context) {
                final schoolsWithInterviews = applications.where((app) => app.interview?.date != null).toList();
                
                if (schoolsWithInterviews.isEmpty) {
                  return Padding(
                    padding: Responsive.symmetric(vertical: 4),
                    child: Divider(color: AppColors.grey200, height: 1),
                  );
                }
                
                return Column(
                  children: [
                    Container(
                      padding: Responsive.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Responsive.r(10)),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.event_available_rounded,
                                size: Responsive.sp(16),
                                color: AppColors.warning,
                              ),
                              SizedBox(width: Responsive.w(6)),
                              Text(
                                'interview_scheduled'.tr,
                                style: AppFonts.bodyMedium.copyWith(
                                  color: AppColors.warning,
                                  fontSize: Responsive.sp(12),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Responsive.h(8)),
                          ...schoolsWithInterviews.map((app) {
                            final index = applications.indexOf(app);
                            String preferenceLabel = '';
                            Color preferenceColor = AppColors.blue1;
                            
                            if (index == 0) {
                              preferenceLabel = 'preference_first'.tr;
                              preferenceColor = AppColors.error;
                            } else if (index == 1) {
                              preferenceLabel = 'preference_second'.tr;
                              preferenceColor = AppColors.success;
                            } else if (index == 2) {
                              preferenceLabel = 'preference_third'.tr;
                              preferenceColor = AppColors.warning;
                            }
                            
                            return Padding(
                              padding: Responsive.only(bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    padding: Responsive.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: preferenceColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(Responsive.r(4)),
                                    ),
                                    child: Text(
                                      preferenceLabel,
                                      style: AppFonts.bodySmall.copyWith(
                                        color: preferenceColor,
                                        fontSize: Responsive.sp(8),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: Responsive.w(6)),
                                  Expanded(
                                    child: Text(
                                      '${app.school.name}: ${_formatDate(app.interview!.date!)}${app.interview!.time != null ? ' - ${_formatTimeDisplay(app.interview!.time!)}' : ''}',
                                      style: AppFonts.bodySmall.copyWith(
                                        color: AppColors.textPrimary,
                                        fontSize: Responsive.sp(10),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    SizedBox(height: Responsive.h(12)),
                    Divider(color: AppColors.grey200, height: 1),
                  ],
                );
              },
            ),
            
            SizedBox(height: Responsive.h(8)),
            
            // Schools List with Preference Order
            ...applications.asMap().entries.map((entry) {
              final index = entry.key;
              final app = entry.value;
              final isPaid = app.payment?.isPaid ?? false;
              final statusColor = _getStatusColor(app.status, isPaid);
              
              String preferenceLabel = '';
              Color preferenceColor = AppColors.blue1;
              
              if (index == 0) {
                preferenceLabel = 'preference_first'.tr;
                preferenceColor = AppColors.error;
              } else if (index == 1) {
                preferenceLabel = 'preference_second'.tr;
                preferenceColor = AppColors.success;
              } else if (index == 2) {
                preferenceLabel = 'preference_third'.tr;
                preferenceColor = AppColors.warning;
              }
              
              return InkWell(
                onTap: () => Get.toNamed(
                  AppRoutes.applicationDetails,
                  arguments: {'applicationId': app.id},
                ),
                borderRadius: BorderRadius.circular(Responsive.r(12)),
                child: Container(
                  margin: Responsive.only(bottom: 8),
                  padding: Responsive.all(10),
                  decoration: BoxDecoration(
                    color: preferenceColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                    border: Border.all(
                      color: preferenceColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Preference Badge
                      Container(
                        padding: Responsive.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: preferenceColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(Responsive.r(6)),
                        ),
                        child: Text(
                          preferenceLabel,
                          style: AppFonts.bodySmall.copyWith(
                            color: preferenceColor,
                            fontSize: Responsive.sp(9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.w(8)),
                      // School Name
                      Expanded(
                        child: Text(
                          app.school.name,
                          style: AppFonts.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: Responsive.sp(13),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: Responsive.w(8)),
                      // Status Badge
                      Container(
                        padding: Responsive.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(Responsive.r(6)),
                        ),
                        child: Text(
                          _getStatusLabel(app.status, isPaid),
                          style: AppFonts.bodySmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.sp(9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            
            SizedBox(height: Responsive.h(4)),
            
            // Footer - Submitted Date
            Container(
              padding: Responsive.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(Responsive.r(8)),
              ),
              child: Row(
                children: [
                  Icon(Icons.send_rounded, size: Responsive.sp(12), color: AppColors.textSecondary),
                  SizedBox(width: Responsive.w(6)),
                  Text(
                    '${'submitted_date'.tr}: ${_formatDate(submittedDate)}',
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: Responsive.sp(11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                application.school.name,
                                style: AppFonts.h4.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: Responsive.sp(15),
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Preference Order Badge
                            Builder(
                              builder: (context) {
                                final preferenceOrder = _getPreferenceOrder(application);
                                if (preferenceOrder == null) return const SizedBox.shrink();
                                
                                String preferenceLabel = '';
                                Color preferenceColor = AppColors.blue1;
                                
                                if (preferenceOrder == 1) {
                                  preferenceLabel = 'preference_first'.tr;
                                  preferenceColor = AppColors.error; // Red
                                } else if (preferenceOrder == 2) {
                                  preferenceLabel = 'preference_second'.tr;
                                  preferenceColor = AppColors.success; // Green
                                } else if (preferenceOrder == 3) {
                                  preferenceLabel = 'preference_third'.tr;
                                  preferenceColor = AppColors.warning; // Yellow
                                }
                                
                                return Container(
                                  margin: Responsive.only(left: 4, right: 4),
                                  padding: Responsive.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: preferenceColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(Responsive.r(6)),
                                  ),
                                  child: Text(
                                    preferenceLabel,
                                    style: AppFonts.bodySmall.copyWith(
                                      color: preferenceColor,
                                      fontSize: Responsive.sp(9),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
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
                    Responsive.isRTL ? IconlyBroken.arrow_left_2 : IconlyBroken.arrow_right_2,
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
