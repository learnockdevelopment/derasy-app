import 'package:flutter/material.dart';
import '../core/utils/responsive_utils.dart';
import '../core/constants/app_fonts.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'dart:async';
import '../core/routes/app_routes.dart';
import '../core/controllers/app_config_controller.dart';

class HeroSectionWidget extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool showFeatures;
  final double borderRadius;
  final List<Widget>? actions;
  final String? title;
  final String? pageTitle; // For backward compatibility
  final String? subtitle;
  final bool showGreeting;

  const HeroSectionWidget({
    Key? key,
    this.userData,
    this.showFeatures = true,
    this.borderRadius = 30,
    this.actions,
    this.title,
    this.pageTitle,
    this.subtitle,
    this.showGreeting = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String greeting = '';
    final hour = DateTime.now().hour;

    if (hour < 12) {
      greeting = 'good_morning'.tr;
    } else if (hour < 17) {
      greeting = 'good_afternoon'.tr;
    } else {
      greeting = 'good_evening'.tr;
    }

    final userName = userData?['name'] ?? userData?['fullName'] ?? 'user'.tr;
    final displayTitle = title ?? pageTitle ?? userName;

    return Obx(() {
      final isDark = AppConfigController.to.isDarkMode;
      // Dark mode: rich deep graphite navy, distinct from the blue gradient
      final gradient = isDark
          ? LinearGradient(
              colors: const [
                Color(0xFF0F172A), // Very dark navy
                Color(0xFF1E293B), // Slate dark
                Color(0xFF1E3A5F), // Deep blue-gray accent
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.55, 1.0],
            )
          : const LinearGradient(
              colors: [
                Color(0xFF1E3A8A), // Deep Navy Blue
                Color(0xFF2563EB), // Primary Blue
                Color(0xFF3B82F6), // Bright Blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.6, 1.0],
            );

      return ClipRect(
        child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          border: isDark
              ? Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                )
              : null,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(Responsive.r(borderRadius)),
            bottomRight: Radius.circular(Responsive.r(borderRadius)),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: Responsive.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Profile & Actions
                Row(
                  children: [
                    // Profile Icon - tapping opens settings/profile
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.userProfile),
                      child: Container(
                        width: Responsive.w(40),
                        height: Responsive.w(40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(isDark ? 0.1 : 0.15),
                          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.2 : 0.3), width: 1.2),
                        ),
                        child: Center(
                          child: Icon(IconlyBold.profile, color: Colors.white, size: Responsive.sp(18)),
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.w(16)),
                    
                    // Welcome Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showGreeting)
                            Text(
                              greeting,
                              style: AppFonts.bodySmall.copyWith(
                                color: Colors.white.withOpacity(isDark ? 0.6 : 0.8),
                                fontWeight: FontWeight.w600,
                                fontSize: Responsive.sp(11),
                              ),
                            ),
                          Text(
                            displayTitle,
                            style: AppFonts.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: Responsive.sp(18),
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Action Buttons
                    if (actions != null) ...actions!
                    else ...[
                      // Notification
                      _HeaderAction(
                        icon: IconlyLight.notification,
                        onTap: () => Get.toNamed(AppRoutes.notifications),
                      ),
                      // Dark / Light toggle
                      _HeaderAction(
                        icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        onTap: () => AppConfigController.to.toggleTheme(),
                      ),
                    ],
                  ],
                ),

                // Content Section - animated info boxes (home only)
                if (showFeatures) ...[
                  SizedBox(height: Responsive.h(12)),
                  const FeatureRotator(moreWhite: true),
                ] else if (subtitle != null) ...[
                  SizedBox(height: Responsive.h(6)),
                  Text(
                    subtitle!,
                    style: AppFonts.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    });
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: Responsive.symmetric(horizontal: 4),
      child: Material(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(Responsive.r(14)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Responsive.r(14)),
          child: Padding(
            padding: Responsive.all(8),
            child: Icon(icon, color: Colors.white, size: Responsive.sp(18)),
          ),
        ),
      ),
    );
  }
}

class FeatureRotator extends StatefulWidget {
  final bool moreWhite;
  const FeatureRotator({Key? key, this.moreWhite = true}) : super(key: key);

  @override
  State<FeatureRotator> createState() => _FeatureRotatorState();
}

class _FeatureRotatorState extends State<FeatureRotator> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late Timer? _timer;
  late PageController _pageController;

  List<Map<String, dynamic>> get _features => [
        {
          'title': 'admission_portal'.tr,
          'subtitle': 'apply_now_hint'.tr,
          'icon': IconlyBold.document,
          'cta': 'apply_now'.tr,
          'route': AppRoutes.applyToSchools,
        },
        {
          'title': 'hero_feature_1_title'.tr, 
          'subtitle': 'hero_feature_1_desc'.tr,
          'icon': IconlyBold.discovery,
          'cta': 'explore'.tr,
          'route': AppRoutes.myStudents,
        },
        {
          'title': 'hero_feature_2_title'.tr,
          'subtitle': 'hero_feature_2_desc'.tr,
          'icon': IconlyBold.activity,
          'cta': 'view_stats'.tr,
          'route': AppRoutes.applications,
        },
      ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentIndex < _features.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final features = _features;
    return Column(
      children: [
        SizedBox(
          height: Responsive.h(60),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return GestureDetector(
                onTap: () => Get.toNamed(feature['route']),
                child: Container(
                  margin: Responsive.symmetric(horizontal: 2),
                  padding: Responsive.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(Responsive.r(18)),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon Container
                      Container(
                        padding: Responsive.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(Responsive.r(12)),
                        ),
                        child: Icon(
                          feature['icon'],
                          color: Colors.white,
                          size: Responsive.sp(16),
                        ),
                      ),
                      SizedBox(width: Responsive.w(12)),
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              feature['title'],
                              style: AppFonts.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: Responsive.sp(12.5),
                                letterSpacing: -0.2,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              feature['subtitle'],
                              style: AppFonts.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: Responsive.sp(10),
                                fontWeight: FontWeight.w500,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: Responsive.h(12)),
        
        // Modern Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(features.length, (index) {
            final double width = _currentIndex == index ? Responsive.w(20) : Responsive.w(6);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: Responsive.symmetric(horizontal: 3),
              width: width,
              height: Responsive.h(6),
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(Responsive.r(3)),
                boxShadow: _currentIndex == index ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 4,
                  )
                ] : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}
