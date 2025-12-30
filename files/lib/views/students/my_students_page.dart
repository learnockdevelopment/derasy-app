import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../models/student_models.dart';
import '../../services/students_service.dart';
import '../../services/user_storage_service.dart';
import '../../services/schools_service.dart';
import '../../services/admission_service.dart';
import '../../models/admission_models.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/hero_section_widget.dart';

class MyStudentsPage extends StatefulWidget { 
  const MyStudentsPage({Key? key}) : super(key: key);

  @override
  State<MyStudentsPage> createState() => _MyStudentsPageState(); 
}

class _MyStudentsPageState extends State<MyStudentsPage> {
  List<Student> _children = [];
  List<Student> _filteredChildren = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _userData;
  Map<String, String> _schoolEducationSystems = {};
  Map<String, List<Application>> _studentApplications = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterChildren);
    _loadUserData();
    _loadChildren();
  }

  Future<void> _loadUserData() async {
    final userData = await UserStorageService.getUserData();
    if (mounted) {
      setState(() {
        _userData = userData;
      });
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
          if (school.educationSystem != null &&
              school.educationSystem!.isNotEmpty) {
            educationSystems[schoolId] = school.educationSystem!;
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

  Future<void> _loadApplications() async {
    try {
      final response = await AdmissionService.getApplications();
      final Map<String, List<Application>> studentApps = {};

      for (var app in response.applications) {
        final childId = app.child.id;
        if (childId.isNotEmpty) {
          studentApps.putIfAbsent(childId, () => []).add(app);
        }
      }

      if (mounted) {
        setState(() {
          _studentApplications = studentApps;
        });
      }
    } catch (e) {
      print('📋 [MY STUDENTS] Error loading applications: $e');
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterChildren);
    _searchController.dispose();
    super.dispose();
  }

  void _filterChildren() {
    if (!mounted) return;
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredChildren = _children;
      } else {
        _filteredChildren = _children.where((child) {
          return child.fullName.toLowerCase().contains(query) ||
              (child.schoolId.name.isNotEmpty &&
                  child.schoolId.name.toLowerCase().contains(query)) ||
              (child.studentClass.name.isNotEmpty &&
                  child.studentClass.name.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  Future<void> _loadChildren() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await StudentsService.getRelatedChildren();
      if (!mounted) return;

      if (response.success) {
        final currentUser = UserStorageService.getCurrentUser();
        if (currentUser == null) {
          if (!mounted) return;
          setState(() {
            _children = [];
            _filteredChildren = [];
            _isLoading = false;
          });
          return;
        }

        final currentUserId = currentUser.id;
        final userJson = currentUser.toJson();
        final currentUserIdAlt = userJson['_id']?.toString() ?? currentUserId;

        final filteredChildren = response.students.where((child) {
          final parentId = child.parent.id;
          return parentId == currentUserId || parentId == currentUserIdAlt;
        }).toList();

        if (!mounted) return;
        setState(() {
          _children = filteredChildren;
          _filteredChildren = filteredChildren;
        });

        // Load schools data and applications after children are loaded
        await _loadSchoolsData();
        await _loadApplications();

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      } else {
        // Response was not successful
        if (!mounted) return;
        setState(() {
          _children = [];
          _filteredChildren = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('👥 [MY STUDENTS] Error loading children: $e');
      if (!mounted) return;
      setState(() {
        _children = [];
        _filteredChildren = [];
        _isLoading = false;
      });
    }
  }

  int _getCurrentIndex() {
    final route = Get.currentRoute;
    if (route == AppRoutes.home) return 0;
    if (route == AppRoutes.students || route == AppRoutes.myStudents) return 1;
    if (route == AppRoutes.applications) return 2;
    if (route == AppRoutes.storeProducts || route == AppRoutes.store) return 3;
    return 1; // Default to My Students
  }

  @override
  Widget build(BuildContext context) {
    final double heroHeight = 120.h;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadChildren();
        },
        color: AppColors.primaryBlue,
        child: CustomScrollView(
          slivers: [
            // Hero Section with dynamic height
            SliverAppBar(
              expandedHeight: heroHeight,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 0,
              collapsedHeight: heroHeight,
              flexibleSpace: FlexibleSpaceBar(
                background: HeroSectionWidget(
                  userData: _userData,
                  pageTitle: 'my_students'.tr,
                  actionButtonText: 'add_student'.tr,
                  actionButtonIcon: IconlyBroken.plus,
                  onActionTap: _navigateToAddChild,
                  showGreeting: false,
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            // Students List
            _isLoading
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                child: SizedBox(height: 100.h)), // Space for FABs
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _getCurrentIndex(),
        onTap: (index) {},
      ),
      floatingActionButton: _buildChatButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _navigateToAddChild() async {
    // Navigate to multi-step add child page
    final result = await Get.toNamed(AppRoutes.addChildSteps);
    if (result == true) {
      // Refresh children list after adding
      await _loadChildren();
    }
  }

  void _navigateToEditChild(Student child) async {
    Get.snackbar(
      'edit_child'.tr,
      'edit_child_feature_coming_soon'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primaryBlue,
      colorText: Colors.white,
    );
  }

  // Future<void> _showDeleteConfirmation(Student child) async {
  //   final confirmed = await Get.dialog<bool>(
  //     AlertDialog(
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(20.r),
  //       ),
  //       title: Text(
  //         'delete_child'.tr,
  //         style: AppFonts.h3.copyWith(
  //           color: AppColors.textPrimary,
  //           fontWeight: FontWeight.bold,
  //           fontSize: 18.sp,
  //         ),
  //       ),
  //       content: Text(
  //         'delete_child_confirmation'.tr.replaceAll('{name}', child.fullName),
  //         style: AppFonts.bodyMedium.copyWith(
  //           color: AppColors.textSecondary,
  //           fontSize: 14.sp,
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Get.back(result: false),
  //           child: Text(
  //             'cancel'.tr,
  //             style: AppFonts.bodyMedium.copyWith(
  //               color: AppColors.textSecondary,
  //               fontSize: 14.sp,
  //             ),
  //           ),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Get.back(result: true),
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.red,
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(12.r),
  //             ),
  //           ),
  //           child: Text(
  //             'delete'.tr,
  //             style: AppFonts.bodyMedium.copyWith(
  //               color: Colors.white,
  //               fontSize: 14.sp,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   if (confirmed == true && mounted) {
  //     await _deleteChild(child);
  //   }
  // }
  //
  // Future<void> _deleteChild(Student child) async {
  //   try {
  //     // Show loading
  //     Get.dialog(
  //       Center(
  //         child: CircularProgressIndicator(
  //           color: AppColors.primaryBlue,
  //         ),
  //       ),
  //       barrierDismissible: false,
  //     );
  //
  //     await StudentsService.deleteChild(child.id);
  //
  //     if (!mounted) return;
  //     Get.back(); // Close loading dialog
  //
  //     // Show success message
  //     Get.snackbar(
  //       'success'.tr,
  //       'child_deleted_successfully'.tr,
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: AppColors.success,
  //       colorText: Colors.white,
  //     );
  //
  //     // Reload children list
  //     await _loadChildren();
  //   } catch (e) {
  //     if (!mounted) return;
  //     Get.back(); // Close loading dialog
  //
  //     // Show error message
  //     Get.snackbar(
  //       'error'.tr,
  //       e.toString().replaceAll('StudentsException: ', ''),
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //     );
  //   }
  // }

  Widget _buildChatButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: FloatingActionButton(
            heroTag: "customer_service_fab_my_students",
            onPressed: () {
              Get.toNamed(AppRoutes.chatbot);
            },
            backgroundColor: AppColors.primaryGreen,
            elevation: 6,
            child: Icon(
              IconlyBold.chat,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
        );
      },
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconlyBroken.profile,
            size: 80.sp,
            color: AppColors.grey400,
          ),
          SizedBox(height: 24.h),
          Text(
            'no_children_found'.tr,
            style: AppFonts.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
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

    return Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.08),
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
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Delete icon - top left
                  // Positioned(
                  //   top: 8.h,
                  //   left: 8.w,
                  //   child: GestureDetector(
                  //     onTap: () => _showDeleteConfirmation(child),
                  //     child: Container(
                  //       width: 32.w,
                  //       height: 32.w,
                  //       decoration: BoxDecoration(
                  //         color: Colors.red.withOpacity(0.1),
                  //         borderRadius: BorderRadius.circular(8.r),
                  //         border: Border.all(
                  //           color: Colors.red.withOpacity(0.3),
                  //           width: 1,
                  //         ),
                  //       ),
                  //       child: Icon(
                  //         IconlyBroken.delete,
                  //         color: Colors.red,
                  //         size: 18.sp,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                       crossAxisAlignment: CrossAxisAlignment.center,
                       children: [
                        // Student Avatar/Initial Circle
                        Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryBlue,
                                AppColors.primaryBlue.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              (child.arabicFullName != null && child.arabicFullName!.isNotEmpty)
                                  ? child.arabicFullName![0].toUpperCase()
                                  : (child.fullName.isNotEmpty
                                      ? child.fullName[0].toUpperCase()
                                      : 'S'),
                              style: AppFonts.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.sp,
                              ),
                            ),
                          ),
                        ),
                         SizedBox(width: 12.w),
                         // Badges beside avatar - centered vertically with avatar (not centered in card)
                         Wrap(
                           spacing: 6.w,
                           runSpacing: 6.h,
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 5.h),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(7.r),
                                  border: Border.all(
                                    color: AppColors.primaryPurple
                                        .withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      IconlyBroken.star,
                                      color: AppColors.primaryPurple,
                                      size: 11.sp,
                                    ),
                                    SizedBox(width: 5.w),
                                    Text(
                                      _translateEducationSystem(
                                          educationSystem.toString().trim()),
                                      style: AppFonts.bodySmall.copyWith(
                                        color: AppColors.primaryPurple,
                                        fontSize: 10.sp,
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 5.h),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(7.r),
                                  border: Border.all(
                                    color:
                                        AppColors.primaryBlue.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      IconlyBroken.document,
                                      color: AppColors.primaryBlue,
                                      size: 11.sp,
                                    ),
                                    SizedBox(width: 5.w),
                                    Text(
                                      child.grade.name,
                                      style: AppFonts.bodySmall.copyWith(
                                        color: AppColors.primaryBlue,
                                        fontSize: 10.sp,
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
                    SizedBox(height: 12.h),
                    // Full name to end of card - no new line
                    Container(
                      child: Text(
                        (child.arabicFullName != null && child.arabicFullName!.isNotEmpty)
                            ? child.arabicFullName!
                            : child.fullName,
                        style: AppFonts.h4.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          letterSpacing: 0.1,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.grey200.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Column(
                        children: [
                          if (child.nationality != null &&
                              child.nationality!.isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(5.w),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(7.r),
                                  ),
                                  child: Icon(
                                    Icons.flag_rounded,
                                    color: AppColors.primaryBlue,
                                    size: 13.sp,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'nationality'.tr,
                                        style: AppFonts.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 1.h),
                                      Text(
                                        _translateNationality(
                                            child.nationality),
                                        style: AppFonts.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          if (child.nationality != null &&
                              child.nationality!.isNotEmpty)
                            SizedBox(height: 8.h),
                          if (schoolName != 'no_school'.tr &&
                              child.schoolId.id.isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(5.w),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(7.r),
                                  ),
                                  child: Icon(
                                    IconlyBroken.document,
                                    color: AppColors.primaryGreen,
                                    size: 13.sp,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'status'.tr,
                                        style: AppFonts.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 1.h),
                                      Text(
                                        'enrolled_in_school'
                                            .tr
                                            .replaceAll('{school}', schoolName),
                                        style: AppFonts.bodyMedium.copyWith(
                                          color: AppColors.primaryGreen,
                                          fontSize: 12.sp,
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
                                  padding: EdgeInsets.all(5.w),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(7.r),
                                  ),
                                  child: Icon(
                                    IconlyBroken.document,
                                    color: Colors.orange,
                                    size: 13.sp,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'status'.tr,
                                        style: AppFonts.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 1.h),
                                      Text(
                                        'not_enrolled_in_school'.tr,
                                        style: AppFonts.bodyMedium.copyWith(
                                          color: Colors.orange.shade700,
                                          fontSize: 12.sp,
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
                            SizedBox(height: 8.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(5.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(7.r),
                                  ),
                                  child: Icon(
                                    IconlyBroken.time_circle,
                                    color: AppColors.primaryPurple,
                                    size: 13.sp,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'age_in_coming_october'.tr,
                                        style: AppFonts.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 1.h),
                                      Text(
                                        _formatAgeInOctober(child.ageInOctober,
                                            child.birthDate),
                                        style: AppFonts.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontSize: 12.sp,
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
                        child.specialNeeds!['hasNeeds'] == true) ...[
                      SizedBox(height: 6.h),
                      Builder(
                        builder: (context) {
                          final specialNeeds = child.specialNeeds!;
                          final description = specialNeeds['description'];
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(7.r),
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
                                  size: 12.sp,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  'special_needs'.tr,
                                  style: AppFonts.bodySmall.copyWith(
                                    color: Colors.orange.shade700,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (description != null &&
                                    description.toString().isNotEmpty) ...[
                                  SizedBox(width: 5.w),
                                  Expanded(
                                    child: Text(
                                      ': ${description}',
                                      style: AppFonts.bodySmall.copyWith(
                                        color: Colors.orange.shade700,
                                        fontSize: 10.sp,
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
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdmissionButton(child),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _buildEditChildButton(child),
                        ),
                      ], 
                    ),
                    // Show "Apply to School" button if student has school and no pending applications
                    if (child.schoolId.id.isNotEmpty) ...[
                      Builder(
                        builder: (context) {
                          final applications = _studentApplications[child.id] ?? [];
                          final pendingStatuses = ['pending', 'under_review', 'waitlist', 'draft'];
                          final hasPendingApplications = applications.any((app) => 
                            pendingStatuses.contains(app.status.toLowerCase())
                          );
                          
                          // Only show "Apply to School" if no pending applications
                          if (!hasPendingApplications) {
                            return Column(
                              children: [
                                SizedBox(height: 8.h),
                                _buildApplyToSchoolButton(child), 
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ],
                ), 
              ), 
            ]),
          ),
        )
    ));
  }

  Widget _buildApplyToSchoolButton(Student child) {
    return SizedBox(
      height: 42.h,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.toNamed(AppRoutes.applyToSchools, arguments: {'childId': child.id});
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  IconlyBroken.plus,
                  color: AppColors.primaryBlue,
                  size: 16.sp,
                ),
                Expanded(
                  child: Text(
                    'apply_to_school'.tr,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.primaryBlue,
                      fontSize: 12.sp,
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

  Widget _buildEditChildButton(Student child) {
    return SizedBox(
      height: 42.h,
      child: OutlinedButton.icon(
        onPressed: () => _navigateToEditChild(child),
        icon: Icon(
          IconlyBroken.edit_square,
          color: AppColors.primaryBlue,
          size: 14.sp,
        ),
        label: Text(
          'edit_child_data'.tr,
          style: AppFonts.h4.copyWith(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
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
        // Get pending applications for this child
        final pendingApps = applications.where((app) => 
          pendingStatuses.contains(app.status.toLowerCase())
        ).toList();
        
        // If only one pending application, open details directly
        if (pendingApps.length == 1) {
          Get.toNamed(
            AppRoutes.applicationDetails,
            arguments: {'applicationId': pendingApps.first.id},
          );
        } else {
          // Multiple applications, go to list page
          Get.toNamed(AppRoutes.applications, arguments: {'childId': child.id});
        }
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
      height: 42.h,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
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
                  size: 16.sp,
                ),
                Expanded(
                  child: Text(
                    buttonText,
                    style: AppFonts.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: 12.sp,
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
      return nationalityMap[lowerNationality]!;
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
      return educationSystemMap[lowerSystem]!;
    }

    for (var entry in educationSystemMap.entries) {
      if (lowerSystem.contains(entry.key) || entry.key.contains(lowerSystem)) {
        return entry.value;
      }
    }

    return educationSystem;
  }
}
