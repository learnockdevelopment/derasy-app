import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
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
  final bool showCart;

  const TopAppBarWidget({
    Key? key,
    this.userData,
    this.showLoading = false,
    this.showCart = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: Responsive.h(Responsive.isTablet || Responsive.isDesktop ? 140 : 80),
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
              padding: Responsive.only(left: 20, top: 10, right: 20, bottom: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      // User Avatar with Badge
                      _buildUserAvatar(),
                      SizedBox(width: Responsive.w(14)),
                      // User Details with Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showLoading)
                              ShimmerLoading(
                                child: Container(
                                  height: Responsive.h(20),
                                  width: Responsive.w(120),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(Responsive.r(4)),
                                  ),
                                ),
                              )
                            else
                              _buildGreeting(),
                             SizedBox(height: Responsive.h(4)),
                            if (showLoading)
                              ShimmerLoading(
                                child: Container(
                                  height: Responsive.h(16),
                                  width: Responsive.w(150),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(Responsive.r(4)),
                                  ),
                                ),
                              )
                            else
                              Text(
                                userData?['name'] ?? 'user'.tr,
                                style: AppFonts.h3.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: Responsive.sp(18),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Cart Icon (only shown when showCart is true)
                      if (showCart)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                            onTap: () {
                              // Prevent double navigation
                              if (Get.currentRoute != AppRoutes.storeCart) {
                                Get.toNamed(AppRoutes.storeCart);
                              }
                            },
                          borderRadius: BorderRadius.circular(Responsive.r(12)),
                          child: Container(
                            padding: Responsive.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(Responsive.r(12)),
                            ),
                            child: Stack(
                              children: [
                                Icon(
                                  Icons.shopping_cart_rounded,
                                  color: Colors.white,
                                  size: Responsive.sp(24),
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

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = 'good_morning'.tr;
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      greeting = 'good_afternoon'.tr;
      greetingIcon = Icons.wb_twilight_rounded;
    } else {
      greeting = 'good_evening'.tr;
      greetingIcon = Icons.nightlight_round;
    }

    return Row(
      children: [
        Icon(
          greetingIcon,
          color: Colors.white.withOpacity(0.9),
          size: Responsive.sp(18),
        ),
        SizedBox(width: Responsive.w(6)),
        Text(
          greeting,
          style: AppFonts.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.95),
            fontSize: Responsive.sp(14),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar() {
    if (showLoading) {
      return ShimmerLoading(
        child: Container(
          width: Responsive.w(44),
          height: Responsive.h(44),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Responsive.r(12)),
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
        borderRadius: BorderRadius.circular(Responsive.r(12)),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2.5,
        ),
      ),
      child: Stack(
        children: [
          Container(
            width: Responsive.w(44),
            height: Responsive.h(44),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Responsive.r(12)),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Responsive.r(12)),
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
              width: Responsive.w(14),
              height: Responsive.h(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(Responsive.r(4)),
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

