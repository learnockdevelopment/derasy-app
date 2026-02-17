import 'package:flutter/material.dart';
import '../core/utils/responsive_utils.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'dart:async';
import '../core/routes/app_routes.dart';

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
    IconData greetingIcon = Icons.wb_sunny;
    final hour = DateTime.now().hour;

    if (hour < 12) {
      greeting = 'good_morning'.tr;
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = 'good_afternoon'.tr;
      greetingIcon = Icons.wb_cloudy;
    } else {
      greeting = 'good_evening'.tr;
      greetingIcon = Icons.nightlight_round;
    }

    final userName = userData?['name'] ?? userData?['fullName'] ?? 'user'.tr;
    final displayTitle = title ?? pageTitle ?? userName;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A), // Deep Navy Blue
            const Color(0xFF2563EB), // Primary Blue
            const Color(0xFF3B82F6), // Bright Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
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
            children: [
              // Top Row: Profile & Actions
              Row(
                children: [
                  // Sleek Profile Image/Icon
                  Container(
                    width: Responsive.w(42),
                    height: Responsive.w(42),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
                    ),
                    child: Center(
                      child: Icon(IconlyBold.profile, color: Colors.white, size: Responsive.sp(20)),
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
                              color: Colors.white.withOpacity(0.8),
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
                    _HeaderAction(
                      icon: IconlyLight.notification,
                      onTap: () => Get.toNamed(AppRoutes.notifications),
                    ),
                    _HeaderAction(
                      icon: IconlyLight.setting,
                      onTap: () => Get.toNamed(AppRoutes.userProfile),
                    ),
                  ],
                ],
              ),

              // Content Section
              if (showFeatures) ...[
                SizedBox(height: Responsive.h(18)),
                const FeatureRotator(moreWhite: true),
              ] else if (subtitle != null) ...[
                SizedBox(height: Responsive.h(8)),
                Text(
                  subtitle!,
                  style: AppFonts.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
          height: Responsive.h(85),
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
              return Container(
                margin: Responsive.symmetric(horizontal: 2),
                padding: Responsive.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(Responsive.r(24)),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      padding: Responsive.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(Responsive.r(16)),
                      ),
                      child: Icon(
                        feature['icon'],
                        color: Colors.white,
                        size: Responsive.sp(24),
                      ),
                    ),
                    SizedBox(width: Responsive.w(15)),
                    
                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            feature['title'],
                            style: AppFonts.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: Responsive.sp(15),
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: Responsive.h(2)),
                          Text(
                            feature['subtitle'],
                            style: AppFonts.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: Responsive.sp(11),
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
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
