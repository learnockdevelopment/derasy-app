import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../models/school_models.dart';
import '../../services/schools_service.dart';
import '../../services/user_storage_service.dart';
import '../schools/schools_page.dart';
import '../profile/user_profile_page.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/safe_network_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  List<School> _schools = [];
  Map<String, dynamic>? _userData;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user data
      final userData = await UserStorageService.getUserData();
      setState(() {
        _userData = userData;
      });

      // Load schools
      final response = await SchoolsService.getAllSchools();
      if (response.success) {
        setState(() {
          _schools = response.schools;
        });
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'network_error'.tr,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          _buildProfileContent(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 100.h, // Reduced height
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFF1E3A8A),
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF3B82F6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      16.w, 16.h, 16.w, 12.h), // Reduced padding
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          // User Avatar
                          _buildUserAvatar(),
                          SizedBox(width: 12.w),
                          // User Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'welcome_back'.tr,
                                  style: AppFonts.h2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp, // Reduced font size
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  _userData?['name'] ?? 'User',
                                  style: AppFonts.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12.sp, // Reduced font size
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w,
                80.h), // Reduced padding, added bottom for navbar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions
                _buildQuickActions(),
                SizedBox(height: 16.h), // Reduced spacing

                // Schools Section
                _buildSchoolsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent() {
    return const UserProfilePage();
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'home'.tr,
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'profile'.tr,
                index: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E3A8A).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFF9CA3AF),
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppFonts.labelSmall.copyWith(
                color: isSelected
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF9CA3AF),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF1E3A8A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'quick_actions'.tr,
                  style: AppFonts.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp, // Reduced font size
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '4',
                    style: AppFonts.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h), // Reduced spacing
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.w, // Further reduced spacing
              mainAxisSpacing: 8.h, // Further reduced spacing
              childAspectRatio:
                  1.3, // Increased aspect ratio for smaller height
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              final actions = [
                {
                  'icon': Icons.school_rounded,
                  'title': 'my_schools'.tr,
                  'subtitle': 'my_schools_description'.tr,
                  'color': const Color(0xFF3B82F6),
                  'onTap': () => Get.to(() => const SchoolsPage()),
                },
                {
                  'icon': Icons.calendar_today_rounded,
                  'title': 'attendance'.tr,
                  'subtitle': 'attendance_description'.tr,
                  'color': const Color(0xFF10B981),
                  'onTap': () => Get.toNamed(AppRoutes.attendance),
                },
                {
                  'icon': Icons.analytics_rounded,
                  'title': 'reports'.tr,
                  'subtitle': 'reports_description'.tr,
                  'color': const Color(0xFFF59E0B),
                  'onTap': () {
                    Get.snackbar(
                      'info'.tr,
                      'reports_coming_soon'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: const Color(0xFF3B82F6),
                      colorText: Colors.white,
                    );
                  },
                },
                {
                  'icon': Icons.settings_rounded,
                  'title': 'settings'.tr,
                  'subtitle': 'settings_description'.tr,
                  'color': const Color(0xFF6B7280),
                  'onTap': () {
                    Get.snackbar(
                      'info'.tr,
                      'settings_coming_soon'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: const Color(0xFF3B82F6),
                      colorText: Colors.white,
                    );
                  },
                },
              ];

              final action = actions[index];
              return _buildActionCard(
                icon: action['icon'] as IconData,
                title: action['title'] as String,
                subtitle: action['subtitle'] as String,
                color: action['color'] as Color,
                onTap: action['onTap'] as VoidCallback,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(12.w), // Reduced padding
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.08),
                color.withOpacity(0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r), // Reduced border radius
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.0, // Reduced border width
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 6, // Reduced blur
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24.w, // Reduced size
                height: 24.h, // Reduced size
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(8.r), // Reduced border radius
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6, // Reduced blur
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16.sp, // Reduced icon size
                ),
              ),
              SizedBox(height: 8.h), // Reduced spacing
              Text(
                title,
                style: AppFonts.bodyMedium.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp, // Reduced font size
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h), // Reduced spacing
              Text(
                subtitle,
                style: AppFonts.bodySmall.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: 9.sp, // Reduced font size
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolsSection() {
    return Container(
      padding: EdgeInsets.all(16.w), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r), // Reduced border radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, // Reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_rounded,
                color: const Color(0xFF10B981),
                size: 20.sp, // Reduced icon size
              ),
              SizedBox(width: 8.w), // Reduced spacing
              Text(
                'my_schools'.tr,
                style: AppFonts.h5.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp, // Reduced font size
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Get.to(() => const SchoolsPage()),
                child: Text(
                  'view_all'.tr,
                  style: AppFonts.labelMedium.copyWith(
                    color: const Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp, // Reduced font size
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            ShimmerActionGrid(itemCount: 4)
          else if (_schools.isEmpty)
            _buildEmptyState()
          else
            _buildSchoolsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(20.w), // Reduced padding
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r), // Reduced border radius
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60.w, // Reduced size
            height: 60.h, // Reduced size
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(30.r), // Reduced border radius
            ),
            child: Icon(
              Icons.school_outlined,
              size: 30.sp, // Reduced icon size
              color: const Color(0xFF3B82F6),
            ),
          ),
          SizedBox(height: 12.h), // Reduced spacing
          Text(
            'no_schools_found'.tr,
            style: AppFonts.h4.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              fontSize: 16.sp, // Reduced font size
            ),
          ),
          SizedBox(height: 4.h), // Reduced spacing
          Text(
            'add_first_school'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: 12.sp, // Reduced font size
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _schools.length > 3 ? 3 : _schools.length,
      itemBuilder: (context, index) {
        final school = _schools[index];
        return _buildSchoolCard(school);
      },
    );
  }

  Widget _buildSchoolCard(School school) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h), // Reduced margin
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10.r), // Reduced border radius
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => const SchoolsPage()),
          borderRadius: BorderRadius.circular(10.r), // Reduced border radius
          child: Padding(
            padding: EdgeInsets.all(12.w), // Reduced padding
            child: Row(
              children: [
                _buildSchoolAvatar(school),
                SizedBox(width: 12.w), // Reduced spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.name,
                        style: AppFonts.bodyMedium.copyWith(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp, // Reduced font size
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h), // Reduced spacing
                      Text(
                        '${school.location?.city ?? 'N/A'}, ${school.location?.governorate ?? 'N/A'}',
                        style: AppFonts.bodySmall.copyWith(
                          color: const Color(0xFF6B7280),
                          fontSize: 11.sp, // Reduced font size
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: const Color(0xFF9CA3AF),
                  size: 14.sp, // Reduced icon size
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    // Get user image from user data
    String? imageUrl = _userData?['avatar'] ??
        _userData?['profileImage'] ??
        _userData?['image'];

    return Container(
      width: 50.w,
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.r),
        child: SafeAvatarImage(
          imageUrl: imageUrl,
          size: 50,
          backgroundColor: const Color(0xFF1E3A8A),
        ),
      ),
    );
  }

  Widget _buildSchoolAvatar(School school) {
    // Get school image from various sources
    String? imageUrl;

    // Try to get image from visibility settings logo
    if (school.visibilitySettings?.officialLogo?.url.isNotEmpty == true) {
      imageUrl = school.visibilitySettings!.officialLogo!.url;
    }
    // Try to get image from media school images
    else if (school.media?.schoolImages?.isNotEmpty == true) {
      imageUrl = school.media!.schoolImages!.first.url;
    }
    // Try to get banner image
    else if (school.bannerImage?.isNotEmpty == true) {
      imageUrl = school.bannerImage;
    }

    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: SafeSchoolImage(
          imageUrl: imageUrl,
          width: 40.w,
          height: 40.h,
        ),
      ),
    );
  }
}
