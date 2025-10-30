import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/school_models.dart';
import '../../services/schools_service.dart';
import '../../services/user_storage_service.dart';
import '../profile/user_profile_page.dart';
import '../widgets/safe_network_image.dart';
import '../../services/user_profile_service.dart';
import '../schools/school_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    });

    try {
      // Load user data
      final userData = await UserStorageService.getUserData();
      // Debug prints
      print('🏠 [HOME] ===========================================');
      print('🏠 [HOME] FULL USER DATA FROM STORAGE:');
      print('🏠 [HOME] ${userData?.toString() ?? 'null'}');
      print('🏠 [HOME] ===========================================');

      setState(() {
        _userData = userData;
      });

      // Ensure avatar is available: if missing, try fetching from API once
      await _ensureUserAvatarLoaded();

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
      });
    }
  }

  Future<void> _ensureUserAvatarLoaded() async {
    try {
      final currentAvatar = _userData?['avatar'] ?? _userData?['profileImage'] ?? _userData?['image'];
      if (currentAvatar == null || (currentAvatar is String && currentAvatar.trim().isEmpty)) {
        final profile = await UserProfileService.getCurrentUserProfile();
        if (mounted) {
          setState(() {
            _userData = {
              ...?_userData,
              'avatar': profile['avatar'] ?? _userData?['avatar'],
              'profileImage': profile['profileImage'] ?? _userData?['profileImage'],
              'image': profile['image'] ?? _userData?['image'],
              'name': profile['name'] ?? _userData?['name'],
              'email': profile['email'] ?? _userData?['email'],
            };
          });
        }
      }
    } catch (e) {
      // Silent: fall back to placeholder
      debugPrint('🏠 [HOME] Unable to fetch avatar from API: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
        // Enhanced App Bar (existing)
        SliverAppBar(
          expandedHeight: 80.h,
          floating: false,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primary,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.98),
                    AppColors.primary.withOpacity(0.88),
                    AppColors.primary.withOpacity(0.78),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                   padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          // User Avatar with Badge
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2.5,
                              ),
                            ),
                            child: Stack(
                              children: [
                                _buildUserAvatar(),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14.w,
                                    height: 14.h,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 14.w),
                          // User Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _userData?['name'] ?? 'User',
                                  style: AppFonts.h2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  _userData?['email'] ?? '',
                                  style: AppFonts.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
        SliverToBoxAdapter(child: SizedBox(height: 20.h)),
        if (_schools.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
              child: _buildSchoolsSuggestions(),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileContent() {
    return const UserProfilePage();
  }

  Widget _buildSchoolsSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34.w,
              height: 34.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.school_rounded, color: AppColors.primary, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Text(
              'my_schools'.tr,
              style: AppFonts.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _schools.length.clamp(0, 4),
          separatorBuilder: (_, __) => SizedBox(height: 20.h),
          itemBuilder: (context, index) {
            final school = _schools[index];
            final imageUrl = _getSchoolImageUrl(school);
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.to(() => SchoolDetailsPage(school: school)),
                  borderRadius: BorderRadius.circular(14.r),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        // Left accent
                        Container(
                          width: 4.w,
                          height: 44.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2.r),
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // Logo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: SizedBox(
                            width: 42.w,
                            height: 42.h,
                            child: SafeSchoolImage(imageUrl: imageUrl, width: 42.w, height: 42.h),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                school.name,
                                style: AppFonts.h4.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 3.h),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, color: AppColors.textSecondary, size: 12.sp),
                                  SizedBox(width: 3.w),
                                  Expanded(
                                    child: Text(
                                      '${school.location?.city ?? 'N/A'}, ${school.location?.governorate ?? 'N/A'}',
                                      style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 10.5.sp),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 14.sp),
                              SizedBox(width: 4.w),
                              Text('view_details'.tr, style: AppFonts.labelSmall.copyWith(color: AppColors.primary, fontSize: 10.sp)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String? _getSchoolImageUrl(School school) {
    if (school.visibilitySettings?.officialLogo?.url.isNotEmpty == true) {
      return school.visibilitySettings!.officialLogo!.url;
    } else if (school.media?.schoolImages?.isNotEmpty == true) {
      return school.media!.schoolImages!.first.url;
    } else if (school.bannerImage?.isNotEmpty == true) {
      return school.bannerImage;
    }
    return null;
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
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : const Color(0xFF9CA3AF),
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppFonts.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.primary
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

  Widget _buildUserAvatar() {
    String? imageUrl = _userData?['avatar']?.toString().trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = _userData?['profileImage']?.toString().trim();
    }
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = _userData?['image']?.toString().trim();
    }

    return Container(
      width: 44.w,
      height: 44.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: SafeAvatarImage(
          imageUrl: imageUrl,
          size: 44,
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }


}
