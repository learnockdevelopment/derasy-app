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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _filterChildId == null 
            ? HorizontalSwipeDetector(
              onSwipeRight: () {
                if (Responsive.isRTL) {
                  // RTL: Swipe Right -> Next Index (1 -> 2)
                  Get.offNamed(AppRoutes.myStudents);
                } else {
                  // LTR: Swipe Right -> Previous Index (1 -> 0)
                  Get.offNamed(AppRoutes.home);
                }
              },
              onSwipeLeft: () {
                if (Responsive.isRTL) {
                  // RTL: Swipe Left -> Previous Index (1 -> 0)
                  Get.offNamed(AppRoutes.home);
                } else {
                  // LTR: Swipe Left -> Next Index (1 -> 2)
                  Get.offNamed(AppRoutes.myStudents);
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
          
          if (_filterChildId == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: const BottomNavBarWidget(),
            ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: null,
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
                    // Go directly to admission flow
                    Get.toNamed(AppRoutes.applyToSchools);
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
                showFeatures: false,
                borderRadius: 20,
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
                  return Padding(
                    padding: Responsive.only(bottom: 12),
                    child: _buildApplicationGroupCard(groupedApplications[index], index + 1),
                  );
                },
                childCount: groupedApplications.length,
              ),
            ),
          ),
        
        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(110))), // Bottom padding
      ],
    );
  }

  Widget _buildApplicationGroupCard(List<Application> applications, int applicationNumber) {
    if (applications.isEmpty) return const SizedBox.shrink();
    
    final firstApp = applications.first;
    final displayName = firstApp.child.arabicFullName ?? firstApp.child.fullName;
    final submittedDate = firstApp.submittedAt ?? firstApp.createdAt;
    
    return Container(
      padding: Responsive.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(24)),
        border: Border.all(
          color: AppColors.blue1.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Batch Info
          Row(
            children: [
              Container(
                padding: Responsive.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                ),
                child: Icon(
                  Icons.auto_awesome_motion_rounded,
                  color: AppColors.blue1,
                  size: Responsive.sp(18),
                ),
              ),
              SizedBox(width: Responsive.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'num_application'.tr} #$applicationNumber',
                      style: AppFonts.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: Responsive.sp(14),
                      ),
                    ),
                    Text(
                      displayName,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: Responsive.sp(11),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: Responsive.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(Responsive.r(10)),
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
          
          SizedBox(height: Responsive.h(16)),
          Divider(color: AppColors.blue1.withOpacity(0.05), height: 1),
          SizedBox(height: Responsive.h(12)),
          
          // Schools List
          ...applications.asMap().entries.map((entry) {
            final index = entry.key;
            final app = entry.value;
            final isPaid = app.payment?.isPaid ?? false;
            final statusColor = _getStatusColor(app.status, isPaid);
            
            // Modern Preference Colors
            final preferenceColor = index == 0 
                ? AppColors.blue1 
                : (index == 1 ? const Color(0xFF06B6D4) : const Color(0xFFF59E0B));
            
            final preferenceLabel = index == 0 
                ? 'preference_first'.tr 
                : (index == 1 ? 'preference_second'.tr : 'preference_third'.tr);

            return Padding(
              padding: EdgeInsets.only(bottom: Responsive.h(10)),
              child: InkWell(
                onTap: () => Get.toNamed(
                  AppRoutes.applicationDetails,
                  arguments: {'applicationId': app.id},
                ),
                borderRadius: BorderRadius.circular(Responsive.r(16)),
                child: Container(
                  padding: Responsive.all(12),
                  decoration: BoxDecoration(
                    color: preferenceColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(Responsive.r(16)),
                    border: Border.all(
                      color: preferenceColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: Responsive.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: preferenceColor,
                          borderRadius: BorderRadius.circular(Responsive.r(8)),
                        ),
                        child: Text(
                          preferenceLabel,
                          style: AppFonts.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: Responsive.sp(9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.w(12)),
                      Expanded(
                        child: Text(
                          app.school.name,
                          style: AppFonts.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: Responsive.sp(13),
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: Responsive.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(Responsive.r(8)),
                        ),
                        child: Text(
                          _getStatusLabel(app.status, isPaid),
                          style: AppFonts.bodySmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                            fontSize: Responsive.sp(9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          
          SizedBox(height: Responsive.h(8)),
          
          // Batch Footer
          Container(
            padding: Responsive.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.blue1.withOpacity(0.04),
              borderRadius: BorderRadius.circular(Responsive.r(12)),
            ),
            child: Row(
              children: [
                Icon(IconlyLight.calendar, size: Responsive.sp(14), color: AppColors.textSecondary),
                SizedBox(width: Responsive.w(8)),
                Expanded(
                  child: Text(
                    '${'submitted_date'.tr}: ${_formatDate(submittedDate)}',
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: Responsive.sp(11),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Transfer Button for Ended Status
                if (applications.any((app) => app.status.toLowerCase() == 'ended'))
                  TextButton.icon(
                    onPressed: () {
                      Get.toNamed(
                        AppRoutes.applyToSchools,
                        arguments: {
                          'child': firstApp.child,
                          'isTransfer': true,
                        },
                      );
                    },
                    icon: Icon(Icons.swap_horiz_rounded, size: Responsive.sp(14)),
                    label: Text('transfer'.tr),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8B5CF6),
                      padding: Responsive.symmetric(horizontal: 8, vertical: 4),
                      textStyle: AppFonts.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.sp(10),
                      ),
                    ),
                  ),
              ],
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

}
