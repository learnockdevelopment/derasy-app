import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../core/constants/assets.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/admission_models.dart';
import '../../models/student_models.dart';
import '../../services/user_storage_service.dart';
import '../../widgets/horizontal_swipe_detector.dart';
import '../../widgets/safe_network_image.dart';
import '../../widgets/shimmer_loading.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../widgets/global_chatbot_widget.dart';
import '../../core/controllers/dashboard_controller.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../widgets/student_selection_sheet.dart';
import '../../widgets/hero_section_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await UserStorageService.getUserData();
    if (mounted) {
      setState(() {
        _userData = userData;
      });
    }
  }

  Future<void> _refreshData() async {
    await DashboardController.to.refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.blue1,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
      body: HorizontalSwipeDetector(
        onSwipeRight: () {
          if (Responsive.isRTL) {
            Get.offNamed(AppRoutes.applications);
          }
        },
        onSwipeLeft: () {
          if (!Responsive.isRTL) {
            Get.offNamed(AppRoutes.applications);
          }
        },
        child: Obx(() => _buildHomeContent()),
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
      floatingActionButton: DraggableChatbotWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    ));
  }

  Widget _buildHomeContent() {
    final controller = DashboardController.to;
    final allApplications = controller.allApplications;
    final isLoading = controller.isLoading &&
        allApplications.isEmpty &&
        controller.relatedChildren.isEmpty;

    if (isLoading) {
      return _buildShimmerLoading();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.blue1,
      child: CustomScrollView( 
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Hero Section
          SliverAppBar(
            expandedHeight: Responsive.h(210),
            floating: false,
            pinned: true,
            snap: false,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 0,
            collapsedHeight: Responsive.h(60),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(Responsive.r(30)),
                bottomRight: Radius.circular(Responsive.r(30)),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: HeroSectionWidget(
                userData: _userData,
                showFeatures: true,
                borderRadius: 30,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(24))),
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              title: 'my_students'.tr,
              onViewAll: () => Get.toNamed(AppRoutes.myStudents), 
            ), 
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: Responsive.h(200),
              child: Obx(() {
                final children = DashboardController.to.relatedChildren;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: Responsive.symmetric(horizontal: 20),
                  itemCount: children.length + 1,
                  itemBuilder: (context, index) {
                    if (index == children.length) {
                      return _buildAddStudentCard();
                    }

                    final child = children[index];
                    return _buildStudentCard(child);
                  },
                );
              }),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(24))),

          // Recent Applications Section
          SliverToBoxAdapter(
            child: _buildRecentApplications(),
          ),

          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(10))),


          // Upcoming Interviews Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              title: 'upcoming_interviews'.tr,
              showViewAll: false,
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(8))),

          // Upcoming Interviews List
          Builder(
            builder: (context) {
              final interviewApps = allApplications
                  .where((app) =>
                      app.interview != null && app.interview?.date != null)
                  .toList()
                ..sort((a, b) =>
                    (a.interview!.date!).compareTo(b.interview!.date!));

              if (controller.isLoading && interviewApps.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: Responsive.symmetric(horizontal: 20),
                    child: ShimmerCard(
                        height: Responsive.h(80),
                        borderRadius: Responsive.r(16)),
                  ),
                );
              }

              if (interviewApps.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: Responsive.symmetric(horizontal: 20),
                    child: Container(
                      padding: Responsive.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(Responsive.r(16)),
                        border: Border.all(color: AppColors.blue1.withOpacity(0.08)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            IconlyBroken.calendar,
                            size: Responsive.sp(40),
                            color: AppColors.grey400,
                          ),
                          SizedBox(height: Responsive.h(8)),
                          Text(
                            'no_upcoming_interviews'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: Responsive.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final app = interviewApps[index];
                      final interviewDate = app.interview!.date!;

                      return Padding(
                        padding: EdgeInsets.only(bottom: Responsive.h(12)),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(Responsive.r(24)),
                          child: InkWell(
                            onTap: () => Get.toNamed(
                                AppRoutes.applicationDetails,
                                arguments: {'applicationId': app.id}),
                            borderRadius:
                                BorderRadius.circular(Responsive.r(24)),
                            child: Container(
                              padding: Responsive.all(16),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(Responsive.r(24)),
                                border: Border.all(
                                    color: AppColors.blue1.withOpacity(0.05)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: Responsive.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue1.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(
                                          Responsive.r(16)),
                                    ),
                                    child: Icon(
                                      IconlyLight.calendar,
                                      color: AppColors.blue1,
                                      size: Responsive.sp(20),
                                    ),
                                  ),
                                  SizedBox(width: Responsive.w(15)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                         app.school.name,
                                          style: AppFonts.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                            fontSize: Responsive.sp(14),
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        SizedBox(height: Responsive.h(4)),
                                        Row(
                                          children: [
                                            Icon(IconlyLight.time_circle,
                                                size: Responsive.sp(12),
                                                color: AppColors.textSecondary),
                                            SizedBox(width: Responsive.w(4)),
                                            Text(
                                              "${DateFormat('EEEE, d MMM', Get.locale?.languageCode).format(interviewDate)} • ${app.interview?.time ?? ''}",
                                              style:
                                                  AppFonts.bodySmall.copyWith(
                                                color: AppColors.textSecondary,
                                                fontSize: Responsive.sp(11),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Responsive.isRTL
                                        ? IconlyLight.arrow_left_2
                                        : IconlyLight.arrow_right_2,
                                    color: AppColors.blue1.withOpacity(0.3),
                                    size: Responsive.sp(16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: interviewApps.length,
                  ),
                ),
              );
            },
          ),

          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(16))),
        ],
      ),
    );
  }


  Widget _buildSectionHeader({
    required String title,
    VoidCallback? onViewAll,
    bool showViewAll = true,
  }) {
    return Padding(
      padding: Responsive.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppFonts.h3.copyWith(
              color: AppColors.textPrimary,
              fontSize: Responsive.sp(16),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (showViewAll)
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(Responsive.r(8)),
              child: Padding(
                padding: Responsive.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'view_all'.tr,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.blue1,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.sp(12),
                      ),
                    ),
                    SizedBox(width: Responsive.w(4)),
                    Icon(
                      Responsive.isRTL
                          ? IconlyLight.arrow_left_2
                          : IconlyLight.arrow_right_2,
                      color: AppColors.blue1,
                      size: Responsive.sp(14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Student child) {
    final fullName = child.arabicFullName ?? child.fullName;
    final bool isEnrolled = child.schoolId.id.isNotEmpty;
    return Padding(
      padding: Responsive.only(right: 15),
      child: GestureDetector(
        onTap: () =>
            Get.toNamed(AppRoutes.childDetails, arguments: {'child': child}),
        child: Container(
          width: 155.w,
          height: 165.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
            ],
            border: Border.all(color: Colors.grey[50]!, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [ 
              // Header: Avatar + Name
              Container(
                width: 65.w, height: 65.w,
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                   gradient: LinearGradient(colors: [AppColors.blue1, Colors.blueAccent]),
                   shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: ClipOval(
                    child: SafeNetworkImage(
                      imageUrl: child.profileImage,
                      width: 65.w,
                      height: 65.w, 
                      fit: BoxFit.cover, 
                      fallbackAsset: AssetsManager.student,
                      placeholder: Image.asset(AssetsManager.student, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  fullName,
                  style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900, fontSize: 13.sp),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 4.h),
              if (isEnrolled)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.blue1.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    child.schoolId.name,
                    style: TextStyle(color: AppColors.blue1, fontSize: 9.sp, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                 Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    'not_enrolled'.tr,
                    style: TextStyle(color: Colors.grey[400], fontSize: 9.sp, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddStudentCard() {
    return Padding(
      padding: Responsive.only(right: 15),
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.addChildSteps),
        child: Container(
          width: 155.w,
          height: 155.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: Responsive.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(IconlyLight.plus,
                    color: AppColors.blue1, size: Responsive.sp(24)),
              ),
              SizedBox(height: Responsive.h(12)),
              Text(
                'add_student'.tr,
                style: AppFonts.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: Responsive.sp(11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return CustomScrollView(
      slivers: [
        // Hero Section Shimmer
        SliverAppBar(
          expandedHeight: Responsive.h(80),
          floating: false,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 0,
          collapsedHeight: Responsive.h(35),
          flexibleSpace: FlexibleSpaceBar( 
            background: HeroSectionWidget(
              userData: null,
              showFeatures: false,
              borderRadius: 30,
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(24))),

        // Apps Grid Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (index) => Column(
                  children: [
                    ShimmerCard(
                      height: Responsive.w(65),
                      width: Responsive.w(65),
                      borderRadius: Responsive.r(20),
                    ),
                    SizedBox(height: Responsive.h(8)),
                    ShimmerCard(
                      height: Responsive.h(12),
                      width: Responsive.w(40),
                      borderRadius: Responsive.r(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(28))),

        // Features Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                    child: ShimmerCard(
                        height: Responsive.h(100),
                        borderRadius: Responsive.r(16))),
                SizedBox(width: Responsive.w(12)),
                Expanded(
                    child: ShimmerCard(
                        height: Responsive.h(100),
                        borderRadius: Responsive.r(16))),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(24))),

        // Students Section Title Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerCard(
                    height: Responsive.h(20),
                    width: Responsive.w(100),
                    borderRadius: Responsive.r(4)),
                ShimmerCard(
                    height: Responsive.h(20),
                    width: Responsive.w(60),
                    borderRadius: Responsive.r(4)),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(12))),

        // Students Carousel Shimmer
        SliverToBoxAdapter(
          child: SizedBox(
            height: Responsive.h(130),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: Responsive.symmetric(horizontal: 20),
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: Responsive.only(right: 12),
                child: ShimmerCard(
                    height: Responsive.h(130),
                    width: Responsive.w(100),
                    borderRadius: Responsive.r(20)),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(24))),

        // Stats Card Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: ShimmerCard(
                height: Responsive.h(210), borderRadius: Responsive.r(20)),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(24))),

        // Interviews Section Title Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: ShimmerCard(
                height: Responsive.h(20),
                width: Responsive.w(150),
                borderRadius: Responsive.r(4)),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(12))),

        // Interviews List Shimmer
        SliverPadding(
          padding: Responsive.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: EdgeInsets.only(bottom: Responsive.h(10)),
                child: ShimmerCard(
                    height: Responsive.h(70), borderRadius: Responsive.r(16)),
              ),
              childCount: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentApplications() {
    final controller = DashboardController.to;
    final apps = controller.allApplications.take(3).toList();
    final isLoading = controller.isLoading && apps.isEmpty;

    return Column(
      children: [
        _buildSectionHeader(
          title: 'recent_applications'.tr,
          onViewAll: () => Get.toNamed(AppRoutes.applications),
          showViewAll: apps.isNotEmpty,
        ),
        if (isLoading)
          Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: ShimmerCard(height: Responsive.h(120), borderRadius: Responsive.r(24)),
          )
        else if (apps.isEmpty)
          Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: _buildEmptyApplicationsState(),
          )
        else
          SizedBox(
            height: Responsive.h(135),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: Responsive.symmetric(horizontal: 20),
              itemCount: apps.length,
              itemBuilder: (context, index) => _buildRecentAppCard(apps[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyApplicationsState() {
    return Container(
      width: double.infinity,
      padding: Responsive.all(24),
      decoration: BoxDecoration(
        color: AppColors.blue1.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Responsive.r(24)),
        border: Border.all(color: AppColors.blue1.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(IconlyBroken.document, color: AppColors.blue1.withOpacity(0.5), size: Responsive.sp(40)),
          SizedBox(height: Responsive.h(12)),
          Text(
            'no_applications_found'.tr,
            style: AppFonts.bodyMedium.copyWith(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: Responsive.h(15)),
          ElevatedButton(
            onPressed: () {
              if (DashboardController.to.relatedChildren.isEmpty) {
                Get.toNamed(AppRoutes.addChildSteps);
              } else {
                 showModalBottomSheet(
                  context: Get.context!,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const StudentSelectionSheet(),
                ).then((selectedStudent) {
                  if (selectedStudent != null && selectedStudent is Student) {
                    Get.toNamed(AppRoutes.applyToSchools, arguments: {'child': selectedStudent});
                  }
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: Responsive.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
            ),
            child: Text('apply_now'.tr, style: AppFonts.bodySmall.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAppCard(Application app) {
    return Padding(
      padding: Responsive.only(right: 15),
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.applicationDetails, arguments: {'applicationId': app.id}),
        child: Container(
          width: Responsive.w(110),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.r(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue1.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.blue1.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: Responsive.w(54),
                height: Responsive.w(54),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.blue1, AppColors.blue1.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue1.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(IconlyBold.document, color: Colors.white, size: Responsive.sp(24)),
                ),
              ),
              SizedBox(height: Responsive.h(12)),
              Padding(
                padding: Responsive.symmetric(horizontal: 8),
                child: Text(
                  app.school.name,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: Responsive.sp(12),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: Responsive.h(6)),
              _buildCompactStatusBadge(app.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatusBadge(String status) {
    Color color = AppColors.blue1;
    if (status.toLowerCase().contains('pending')) color = Colors.orange;
    if (status.toLowerCase().contains('approved')) color = Colors.green;
    if (status.toLowerCase().contains('rejected')) color = Colors.red;

    return Container(
      padding: Responsive.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(Responsive.r(6)),
      ),
      child: Text(
        status.toLowerCase().tr,
        style: AppFonts.bodySmall.copyWith(
          color: color, 
          fontWeight: FontWeight.w900, 
          fontSize: Responsive.sp(9),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
