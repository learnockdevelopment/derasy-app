import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';
import '../core/routes/app_routes.dart';
import 'safe_network_image.dart';
import 'shimmer_loading.dart';

/// Reusable top app bar widget that displays user avatar, name, email, and cart icon
/// Can be used as a SliverAppBar in CustomScrollView
class TopAppBarWidget extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool showLoading;

  const TopAppBarWidget({
    Key? key,
    this.userData,
    this.showLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 80.h,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primaryBlue,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue.withOpacity(0.98),
                AppColors.primaryBlue.withOpacity(0.88),
                AppColors.primaryBlue.withOpacity(0.78),
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
                      _buildUserAvatar(),
                      SizedBox(width: 14.w),
                      // User Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showLoading)
                              ShimmerLoading(
                                child: Container(
                                  height: 20.h,
                                  width: 120.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ),
                              )
                            else
                              Text(
                                userData?['name'] ?? 'user'.tr,
                                style: AppFonts.h2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppFonts.size20,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            SizedBox(height: 2.h),
                            if (showLoading)
                              ShimmerLoading(
                                child: Container(
                                  height: 14.h,
                                  width: 150.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ),
                              )
                            else
                              Text(
                                userData?['email'] ?? '',
                                style: AppFonts.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: AppFonts.size12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Cart Icon
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Get.toNamed(AppRoutes.storeCart),
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Stack(
                              children: [
                                Icon(
                                  Icons.shopping_cart_rounded,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                                // Badge for cart items count (optional - can be added later)
                              ],
                            ),
                          ),
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
    );
  }

  Widget _buildUserAvatar() {
    if (showLoading) {
      return ShimmerLoading(
        child: Container(
          width: 44.w,
          height: 44.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.3),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2.5,
            ),
          ),
        ),
      );
    }

    // Safely extract image URL, handling null values properly
    String? imageUrl;

    // Try avatar field
    final avatar = userData?['avatar'];
    if (avatar != null &&
        avatar is String &&
        avatar.trim().isNotEmpty &&
        avatar.trim().toLowerCase() != 'null') {
      imageUrl = avatar.trim();
    }

    // Try profileImage field
    if (imageUrl == null || imageUrl.isEmpty) {
      final profileImage = userData?['profileImage'];
      if (profileImage != null &&
          profileImage is String &&
          profileImage.trim().isNotEmpty &&
          profileImage.trim().toLowerCase() != 'null') {
        imageUrl = profileImage.trim();
      }
    }

    // Try image field
    if (imageUrl == null || imageUrl.isEmpty) {
      final image = userData?['image'];
      if (image != null &&
          image is String &&
          image.trim().isNotEmpty &&
          image.trim().toLowerCase() != 'null') {
        imageUrl = image.trim();
      }
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2.5,
        ),
      ),
      child: Stack(
        children: [
          Container(
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
                imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
                size: 44,
                backgroundColor: AppColors.primaryBlue,
              ),
            ),
          ),
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
    );
  }
}

