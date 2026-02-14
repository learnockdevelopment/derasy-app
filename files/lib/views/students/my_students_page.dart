import 'package:flutter/material.dart';

import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../models/student_models.dart';
import '../../services/user_storage_service.dart';
import '../../services/schools_service.dart';
import '../../models/admission_models.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/hero_section_widget.dart';
import '../../core/controllers/dashboard_controller.dart';
import '../../widgets/horizontal_swipe_detector.dart';
import '../../widgets/student_selection_sheet.dart';

class MyStudentsPage extends StatefulWidget { 
  const MyStudentsPage({Key? key}) : super(key: key);

  @override
  State<MyStudentsPage> createState() => _MyStudentsPageState(); 
}

class _MyStudentsPageState extends State<MyStudentsPage> {
  List<Student> _children = [];
  List<Student> _filteredChildren = [];
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _userData;
  Map<String, String> _schoolEducationSystems = {};
  Map<String, List<Application>> _studentApplications = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterChildren);
    _loadUserData();
    
    // Listen to changes in DashboardController to update local state
    final controller = DashboardController.to;
    ever(controller.relatedChildren, (_) => _syncWithController());
    ever(controller.allApplications, (_) => _syncWithController());
    
    // Initial sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithController();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterChildren);
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

  void _syncWithController() {
    final controller = DashboardController.to;
    
    // Initial sync
    _updateLocalState(controller.relatedChildren, controller.allApplications);
    
    // We'll use Obx in the build method for reactivity, 
    // but we still need to filter when data arrives.
  }

  void _updateLocalState(List<Student> students, List<Application> applications) {
    if (!mounted) return;

    final currentUser = UserStorageService.getCurrentUser();
    if (currentUser == null) {
      setState(() {
        _children = [];
        _filteredChildren = [];
        _studentApplications = {};
      });
      return;
    }

    // Trust the API to return related children
    final filteredChildren = students;

    // Map applications to students
    final Map<String, List<Application>> studentApps = {};
    for (var app in applications) {
      final childId = app.child.id;
      if (childId.isNotEmpty) {
        studentApps.putIfAbsent(childId, () => []).add(app);
      }
    }

    setState(() {
      _children = filteredChildren;
      _studentApplications = studentApps;
      _filterChildren();
    });

    if (filteredChildren.isNotEmpty) {
      _loadSchoolsData();
    }
  }

  Future<void> _loadSchoolsData() async {
    try {
      final Set<String> uniqueSchoolIds = {};
      for (var child in _children) {
        if (child.schoolId.id.isNotEmpty) {
          uniqueSchoolIds.add(child.schoolId.id);
        }
      }

      if (uniqueSchoolIds.isEmpty) return;

      final Map<String, String> educationSystems = {};
      for (var schoolId in uniqueSchoolIds) {
        try {
          final school = await SchoolsService.getSchoolById(schoolId);
          final system = school.educationSystem;
          if (system != null && system.isNotEmpty) {
            educationSystems[schoolId] = system;
          }
        } catch (e) {
          // Continue with other schools
        }
      }

      if (mounted) {
        setState(() {
          _schoolEducationSystems = educationSystems;
        });
      }
    } catch (e) {
      print('🏫 [MY STUDENTS] Error loading schools data: $e');
    }
  }

  Future<void> _onRefresh() async {
    await DashboardController.to.refreshAll();
    _syncWithController();
  }

  void _filterChildren() {
    if (!mounted) return;
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredChildren = _children;
      } else {
        _filteredChildren = _children.where((child) {
          return (child.arabicFullName?.toLowerCase().contains(query) ?? false) ||
              (child.schoolId.name.isNotEmpty &&
                  child.schoolId.name.toLowerCase().contains(query)) ||
              (child.studentClass.name.isNotEmpty &&
                  child.studentClass.name.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Responsive.h(120);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: HorizontalSwipeDetector(
        onSwipeRight: () {
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
            Get.offNamed(AppRoutes.home);
          }
        },
        onSwipeLeft: () {
          if (Responsive.isRTL) {
            Get.offNamed(AppRoutes.home);
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
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.blue1,
          child: Obx(() {
            final controller = DashboardController.to;
            final isLoading = controller.isLoading;
            
            // Local state is now synced via listeners in initState
            // to avoid calling setState() during build.

            return CustomScrollView(
              slivers: [
                // Hero Section with dynamic height
                SliverAppBar(
                  expandedHeight: Responsive.h(Responsive.isTablet || Responsive.isDesktop ? 140 : 80),
                  floating: false,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 0,
                  collapsedHeight: Responsive.h(45),
                  flexibleSpace: FlexibleSpaceBar(
                    background: HeroSectionWidget(
                      userData: _userData,
                      pageTitle: 'my_students'.tr,
                      showGreeting: false,
                    ),
                  ),
                ),

                if (controller.isTakingLong && isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: Responsive.symmetric(horizontal: 16, vertical: 12),
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

                if (controller.isTimeout && !isLoading && _filteredChildren.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: Responsive.symmetric(horizontal: 16, vertical: 12),
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

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: Responsive.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.blue1, AppColors.blue1.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(Responsive.r(16)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue1.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _navigateToAddChild,
                            borderRadius: BorderRadius.circular(Responsive.r(16)),
                            child: Padding(
                              padding: Responsive.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(IconlyBold.plus, color: Colors.white, size: Responsive.sp(20)),
                                  SizedBox(width: Responsive.w(12)),
                                  Text(
                                    'add_student'.tr,
                                    style: AppFonts.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: Responsive.sp(14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: Responsive.h(4))),
                // Students List
                isLoading && _filteredChildren.isEmpty
                    ? SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Padding(
                              padding: Responsive.symmetric(horizontal: 16),
                              child: const ShimmerListTile(),
                            );
                          },
                          childCount: 10,
                        ),
                      )
                    : _filteredChildren.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(),
                          )
                        : SliverPadding(
                            padding: Responsive.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _buildStudentListItem(
                                      _filteredChildren[index], index);
                                },
                                childCount: _filteredChildren.length,
                              ),
                            ),
                          ),
                SliverToBoxAdapter(
                    child: SizedBox(height: Responsive.h(100))), // Space for FABs
              ],
            );
          }),
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }

  void _navigateToAddChild() async {
    // Navigate to multi-step add child page
    final result = await Get.toNamed(AppRoutes.addChildSteps);
    if (result == true) {
      // Refresh children list after adding
      await DashboardController.to.refreshAll();
      _syncWithController();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconlyBroken.profile,
            size: Responsive.sp(80),
            color: AppColors.grey400,
          ),
          SizedBox(height: Responsive.h(24)),
          Text(
            'no_children_found'.tr,
            style: AppFonts.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            'no_children_found_message'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatAgeInOctober(int ageInMonths, String? birthDate) {
    // Convert months to years and months
    final years = ageInMonths ~/ 12;
    final months = ageInMonths % 12;

    // Calculate days from birth date if available
    int days = 0;
    if (birthDate != null && birthDate.isNotEmpty) {
      try {
        final birth = DateTime.parse(birthDate);
        final now = DateTime.now();
        // Calculate age in October (target date)
        final targetDate = now.month < 10
            ? DateTime(now.year, 10, 1)
            : DateTime(now.year + 1, 10, 1);

        // Calculate total days difference
        final totalDays = targetDate.difference(birth).inDays;

        // Calculate remaining days after years and months
        final totalMonthsFromBirth =
            (totalDays / 30.44).floor(); // Average days per month
        final remainingDays =
            totalDays - (totalMonthsFromBirth * 30.44).round();
        days = remainingDays.round().abs();
      } catch (e) {
        // If parsing fails, days will remain 0
      }
    }

    // Build formatted string
    final parts = <String>[];
    if (years > 0) {
      parts.add('$years ${years == 1 ? 'year'.tr : 'years'.tr}');
    }
    if (months > 0) {
      parts.add('$months ${months == 1 ? 'month'.tr : 'months'.tr}');
    }
    if (days > 0) {
      parts.add('$days ${days == 1 ? 'day'.tr : 'days'.tr}');
    }

    return parts.isEmpty ? '0 ${'months'.tr}' : parts.join(' - ');
  }

  Widget _buildStudentListItem(Student child, int index) {
    final schoolName =
        child.schoolId.name.isNotEmpty ? child.schoolId.name : 'no_school'.tr;

    final schoolId = child.schoolId.id;
    final educationSystem =
        _schoolEducationSystems[schoolId] ?? child.schoolId.educationSystem;

    final isMale = child.gender.toLowerCase() == 'male' || child.gender == 'ذكر';
    final studentColor = isMale ? AppColors.blue1 : const Color(0xFFEC407A); // Pink 400 for girls
    final studentBgColor = studentColor.withOpacity(0.1);

    return Container(
        margin: Responsive.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Responsive.r(16)),
          boxShadow: [
            BoxShadow(
              color: studentColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Get.toNamed(AppRoutes.childDetails, arguments: {'child': child});
            },
            borderRadius: BorderRadius.circular(Responsive.r(20)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Responsive.r(20)),
                border: Border.all(
                  color: studentColor.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Delete icon - top left
                  // Positioned(
                  //   top: Responsive.h(8),
                  //   left: Responsive.w(8),
                  //   child: GestureDetector(
                  //     onTap: () => _showDeleteConfirmation(child),
                  //     child: Container(
                  //       width: Responsive.w(32),
                  //       height: Responsive.w(32),
                  //       decoration: BoxDecoration(
                  //         color: Colors.red.withOpacity(0.1),
                  //         borderRadius: BorderRadius.circular(Responsive.r(8)),
                  //         border: Border.all(
                  //           color: Colors.red.withOpacity(0.3),
                  //           width: 1,
                  //         ),
                  //       ),
                  //       child: Icon(
                  //         IconlyBroken.delete,
                  //         color: Colors.red,
                  //         size: Responsive.sp(18),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  Padding(
                    padding: Responsive.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                       crossAxisAlignment: CrossAxisAlignment.center,
                       children: [
                        // Student Avatar/Initial Circle
                        Container(
                          width: Responsive.w(40),
                          height: Responsive.w(40),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                studentColor,
                                studentColor.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                            boxShadow: [
                              BoxShadow(
                                color: studentColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              (child.arabicFullName != null && child.arabicFullName!.isNotEmpty)
                                  ? (child.arabicFullName![0].toUpperCase())
                                  : 'S',
                              style: AppFonts.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.sp(16),
                              ),
                            ),
                          ),
                        ),
                         SizedBox(width: Responsive.w(12)),
                          // Badges beside avatar - centered vertically with avatar (not centered in card)
                         Wrap(
                           spacing: Responsive.w(6),
                           runSpacing: Responsive.h(6),
                           alignment: WrapAlignment.start,
                           crossAxisAlignment: WrapCrossAlignment.center,
                           children: [
                            if (educationSystem != null &&
                                educationSystem.isNotEmpty &&
                                educationSystem.toString().trim().isNotEmpty &&
                                educationSystem.toString().trim() != 'null' &&
                                schoolName != 'no_school'.tr &&
                                child.schoolId.id.isNotEmpty)
                              Container(
                                padding: Responsive.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                    color:
                                       studentColor.withOpacity(0.1),
                                   borderRadius: BorderRadius.circular(Responsive.r(7)),
                                   border: Border.all(
                                     color: studentColor
                                         .withOpacity(0.2),
                                     width: 1,
                                   ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                      Icon(
                                       IconlyBroken.star,
                                       color: studentColor,
                                       size: Responsive.sp(11),
                                     ),
                                     SizedBox(width: Responsive.w(5)),
                                     Text(
                                       _translateEducationSystem(
                                           educationSystem.toString().trim()),
                                       style: AppFonts.bodySmall.copyWith(
                                         color: studentColor,
                                         fontSize: Responsive.sp(10),
                                         fontWeight: FontWeight.w600,
                                       ),
                                     ),
                                  ],
                                ),
                              ),
                            if (child.grade.name.isNotEmpty &&
                                child.grade.name != 'N/A' &&
                                schoolName != 'no_school'.tr &&
                                child.schoolId.id.isNotEmpty)
                              Container(
                                padding: Responsive.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                   color: studentColor.withOpacity(0.1),
                                   borderRadius: BorderRadius.circular(Responsive.r(7)),
                                   border: Border.all(
                                     color:
                                         studentColor.withOpacity(0.2),
                                     width: 1,
                                   ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                     Icon(
                                       IconlyBroken.document,
                                       color: studentColor,
                                       size: Responsive.sp(11),
                                     ),
                                     SizedBox(width: Responsive.w(5)),
                                     Text(
                                       child.grade.name,
                                       style: AppFonts.bodySmall.copyWith(
                                         color: studentColor,
                                         fontSize: Responsive.sp(10),
                                         fontWeight: FontWeight.w600,
                                       ),
                                     ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                      ],
                    ),
                    SizedBox(height: Responsive.h(12)),
                    // Full name to end of card - no new line
                    Container(
                      child: Text(
                        child.arabicFullName ?? '',
                        style: AppFonts.h4.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.sp(15),
                          letterSpacing: 0.1,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),                    Container(
                      padding: Responsive.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.grey200.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(Responsive.r(10)),
                      ),
                      child: Column(
                        children: [
                          if (child.nationality != null &&
                              (child.nationality?.isNotEmpty ?? false))
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: Responsive.all(5),
                                  decoration: BoxDecoration(
                                     color:
                                         studentColor.withOpacity(0.1),
                                     borderRadius: BorderRadius.circular(Responsive.r(7)),
                                   ),
                                   child: Icon(
                                     Icons.flag_rounded,
                                     color: studentColor,
                                     size: Responsive.sp(13),
                                   ),
                                ),
                                SizedBox(width: Responsive.w(8)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'nationality'.tr,
                                        style: AppFonts.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: Responsive.sp(10),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: Responsive.h(1)),
                                      Text(
                                        _translateNationality(
                                            child.nationality),
                                        style: AppFonts.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontSize: Responsive.sp(12),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          if (child.nationality != null &&
                              (child.nationality?.isNotEmpty ?? false))
                            SizedBox(height: Responsive.h(8)),
                          if (schoolName != 'no_school'.tr &&
                              child.schoolId.id.isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: Responsive.all(5),
                                  decoration: BoxDecoration(
                                     color:
                                         studentColor.withOpacity(0.1),
                                     borderRadius: BorderRadius.circular(Responsive.r(7)),
                                   ),
                                   child: Icon(
                                     IconlyBroken.document,
                                     color: studentColor,
                                     size: Responsive.sp(13),
                                   ),
                                ),
                                SizedBox(width: Responsive.w(8)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'status'.tr,
                                        style: AppFonts.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: Responsive.sp(10),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: Responsive.h(1)),
                                       Text(
                                         'enrolled_in_school'
                                             .tr
                                             .replaceAll('{school}', schoolName),
                                         style: AppFonts.bodyMedium.copyWith(
                                           color: studentColor,
                                           fontSize: Responsive.sp(12),
                                           fontWeight: FontWeight.w600,
                                         ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else if (schoolName == 'no_school'.tr ||
                              child.schoolId.id.isEmpty)
                            Row(
                              children: [
                                Container(
                                  padding: Responsive.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(Responsive.r(7)),
                                  ),
                                  child: Icon(
                                    IconlyBroken.document,
                                    color: Colors.orange,
                                    size: Responsive.sp(13),
                                  ),
                                ),
                                SizedBox(width: Responsive.w(8)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'status'.tr,
                                        style: AppFonts.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: Responsive.sp(10),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: Responsive.h(1)),
                                      Text(
                                        'not_enrolled_in_school'.tr,
                                        style: AppFonts.bodyMedium.copyWith(
                                          color: Colors.orange.shade700,
                                          fontSize: Responsive.sp(12),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          // Age in October - displayed below school info
                          if (child.ageInOctober > 0) ...[
                            SizedBox(height: Responsive.h(8)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: Responsive.all(5),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue2
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(Responsive.r(7)),
                                  ),
                                  child: Icon(
                                    IconlyBroken.time_circle,
                                    color: AppColors.blue2,
                                    size: Responsive.sp(13),
                                  ),
                                ),
                                SizedBox(width: Responsive.w(8)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'age_in_coming_october'.tr,
                                        style: AppFonts.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: Responsive.sp(10),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),

                                      SizedBox(height: Responsive.h(1)),
                                      Text(
                                        _formatAgeInOctober(child.ageInOctober,
                                            child.birthDate),
                                        style: AppFonts.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontSize: Responsive.sp(12),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (child.specialNeeds != null &&
                        child.specialNeeds?['hasNeeds'] == true) ...[
                      SizedBox(height: Responsive.h(6)),
                      Builder(
                        builder: (context) {
                          final specialNeeds = child.specialNeeds ?? {};
                          final description = specialNeeds['description'];
                          return Container(
                            padding: Responsive.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(Responsive.r(7)),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  IconlyBroken.profile,
                                  color: Colors.orange,
                                  size: Responsive.sp(12),
                                ),
                                SizedBox(width: Responsive.w(5)),
                                Text(
                                  'special_needs'.tr,
                                  style: AppFonts.bodySmall.copyWith(
                                    color: Colors.orange.shade700,
                                    fontSize: Responsive.sp(11),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (description != null &&
                                    description.toString().isNotEmpty) ...[
                                  SizedBox(width: Responsive.w(5)),
                                  Expanded(
                                    child: Text(
                                      ': ${description}',
                                      style: AppFonts.bodySmall.copyWith(
                                        color: Colors.orange.shade700,
                                        fontSize: Responsive.sp(10),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    SizedBox(height: Responsive.h(12)),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdmissionButton(child),
                        ),
                      ], 
                    ),

                  ],
                ), 
              ), 
            ]),
          ),
        ),
      ),
    );
}

  Widget _buildAdmissionButton(Student child) {
    final hasSchool = child.schoolId.id.isNotEmpty;
    final applications = _studentApplications[child.id] ?? [];
    
    // Check if there are pending/in-progress applications
    final pendingStatuses = ['pending', 'under_review', 'waitlist', 'draft'];
    final hasPendingApplications = applications.any((app) => 
      pendingStatuses.contains(app.status.toLowerCase())
    );

    String buttonText;
    VoidCallback? onTap;

    // If has pending applications (regardless of school status) → show application
    if (hasPendingApplications) {
      buttonText = 'show_application'.tr;
      onTap = () {
        // Always go to list page as requested to "redirect to Applications page"
        Get.toNamed(AppRoutes.applications, arguments: {'childId': child.id});
      };
    } 
    // If no pending applications and has school → show "apply to other school"
    else if (hasSchool) {
      buttonText = 'apply_to_other_school'.tr;
      onTap = () {
        Get.toNamed(AppRoutes.applyToSchools, arguments: {'childId': child.id});
      };
    } 
    // If no pending applications and no school → show "apply to school"
    else {
      buttonText = 'apply_to_school'.tr;
      onTap = () {
        Get.toNamed(AppRoutes.applyToSchools, arguments: {'childId': child.id});
      };
    }

    return SizedBox(
      height: Responsive.h(42),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Responsive.r(12)),
          child: Container(
            width: double.infinity,
            padding: Responsive.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.blue1,
                  AppColors.blue1.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue1.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasPendingApplications
                      ? IconlyBroken.document
                      : IconlyBroken.plus,
                  color: Colors.white,
                  size: Responsive.sp(16),
                ),
                Expanded(
                  child: Text(
                    buttonText,
                    style: AppFonts.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: Responsive.sp(12),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _translateNationality(String? nationality) {
    if (nationality == null || nationality.isEmpty) return '';
    if (Get.locale?.languageCode != 'ar') return nationality;

    final lowerNationality = nationality.toLowerCase();
    final nationalityMap = {
      'egyptian': 'مصرى',
      'saudi': 'سعودي',
      'emirati': 'إماراتي',
      'kuwaiti': 'كويتي',
      'qatari': 'قطري',
      'bahraini': 'بحريني',
      'omani': 'عماني',
      'jordanian': 'أردني',
      'lebanese': 'لبناني',
      'syrian': 'سوري',
      'iraqi': 'عراقي',
      'palestinian': 'فلسطيني',
      'yemeni': 'يمني',
      'sudanese': 'سوداني',
      'libyan': 'ليبي',
      'tunisian': 'تونسي',
      'algerian': 'جزائري',
      'moroccan': 'مغربي',
    };

    if (nationalityMap.containsKey(lowerNationality)) {
      return nationalityMap[lowerNationality] ?? nationality;
    }

    for (var entry in nationalityMap.entries) {
      if (lowerNationality.contains(entry.key) ||
          entry.key.contains(lowerNationality)) {
        return entry.value;
      }
    }

    return nationality;
  }

  String _translateEducationSystem(String educationSystem) {
    if (educationSystem.isEmpty) return '';
    if (Get.locale?.languageCode != 'ar') return educationSystem;

    final lowerSystem = educationSystem.toLowerCase();
    final educationSystemMap = {
      'national language': 'محلي لغات',
      'national': 'محلي عربي',
      'american': 'أمريكي',
      'american system': 'نظام أمريكي',
      'british': 'بريطاني',
      'british system': 'نظام بريطاني',
      'igcse': 'آي جي سي إس إي',
      'international baccalaureate': 'البكالوريا الدولية',
      'ib': 'البكالوريا الدولية',
      'french': 'فرنسي',
      'french system': 'نظام فرنسي',
      'german': 'ألماني',
      'german system': 'نظام ألماني',
      'canadian': 'كندي',
      'canadian system': 'نظام كندي',
      'australian': 'أسترالي',
      'australian system': 'نظام أسترالي',
    };

    if (educationSystemMap.containsKey(lowerSystem)) {
      return educationSystemMap[lowerSystem] ?? educationSystem;
    }

    for (var entry in educationSystemMap.entries) {
      if (lowerSystem.contains(entry.key) || entry.key.contains(lowerSystem)) {
        return entry.value;
      }
    }

    return educationSystem;
  }
}

