import 'package:flutter/material.dart';
import '../core/utils/responsive_utils.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'dart:async';

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
          colors: [AppColors.blue1, AppColors.blue2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(Responsive.r(borderRadius)),
          bottomRight: Radius.circular(Responsive.r(borderRadius)),
        ),
      ),
      child: Stack(
        children: [
          // Decorative Elements
          Positioned(
            top: -Responsive.h(50),
            right: -Responsive.w(50),
            child: Container(
              width: Responsive.w(150),
              height: Responsive.w(150),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: Responsive.symmetric(horizontal: 20),
              child: Column(
                children: [
                   SizedBox(height: Responsive.h(10)),
                  // User Profile Row
                  Row(
                    children: [
                      Container(
                        width: Responsive.w(50),
                        height: Responsive.w(50),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(IconlyBold.profile, color: Colors.white, size: Responsive.sp(24)),
                        ),
                      ),
                      SizedBox(width: Responsive.w(15)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showGreeting)
                              Row(
                                children: [
                                  Text(
                                    greeting,
                                    style: AppFonts.bodySmall.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                      fontSize: Responsive.sp(11),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(greetingIcon, color: Colors.amber, size: Responsive.sp(14)),
                                ],
                              ),
                            Text(
                              displayTitle,
                              style: AppFonts.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: Responsive.sp(18),
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (actions != null) ...actions!
                      else ...[
                         _HeaderAction(
                          icon: Icons.notifications_none_rounded,
                          onTap: () {},
                        ),
                      ],
                    ],
                  ),
                  if (showFeatures) ...[
                    SizedBox(height: Responsive.h(15)),
                    const FeatureRotator(moreWhite: true),
                  ] else if (subtitle != null) ...[
                    SizedBox(height: Responsive.h(10)),
                    Padding(
                      padding: EdgeInsets.only(left: Responsive.w(60)),
                      child: Text(
                        subtitle!,
                        style: AppFonts.bodySmall.copyWith(color: Colors.white.withOpacity(0.9)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: Responsive.symmetric(horizontal: 5),
        padding: Responsive.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(Responsive.r(12)),
        ),
        child: Icon(icon, color: Colors.white, size: Responsive.sp(20)),
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
  late Timer _timer;
  late PageController _pageController;

  List<Map<String, dynamic>> get _features => [
        {
          'title': 'admission_portal'.tr,
          'subtitle': 'apply_now_hint'.tr,
          'icon': IconlyBold.document,
          'color': AppColors.blue200,
        },
        {
          'title': 'hero_feature_1_title'.tr, 
          'subtitle': 'hero_feature_1_desc'.tr,
          'icon': IconlyBold.discovery,
          'color': AppColors.blue200,
        },
        {
          'title': 'hero_feature_2_title'.tr,
          'subtitle': 'hero_feature_2_desc'.tr,
          'icon': IconlyBold.activity,
          'color': AppColors.blue200,
        },
        {
          'title': 'hero_feature_3_title'.tr,
          'subtitle': 'hero_feature_3_desc'.tr,  
          'icon': IconlyBold.time_circle, 
          'color': AppColors.blue200,
        },
      ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentIndex < _features.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final features = _features;
    return Column(
      children: [
        SizedBox(
          height: Responsive.h(110),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: features.length,
            itemBuilder: (context, index) {
              final featureIndex = index % features.length;
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                  } else {
                    value = index == 0 ? 1.0 : 0.85;
                  }

                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Padding(
                  padding: Responsive.symmetric(horizontal: 4),
                  child: Container(
                    padding: Responsive.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.blue2.withOpacity(0.95),
                          AppColors.blue1.withOpacity(0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(Responsive.r(24)),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: Responsive.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                          ),
                          child: Icon(
                            features[featureIndex]['icon'],
                            color: Colors.white,
                            size: Responsive.sp(22),
                          ),
                        ),
                        SizedBox(width: Responsive.w(15)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                features[featureIndex]['title'],
                                style: AppFonts.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: Responsive.sp(14),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: Responsive.h(2)),
                              Text(
                                features[featureIndex]['subtitle'],
                                style: AppFonts.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: Responsive.sp(11),
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
                ),
              );
            },
          ),
        ),
        SizedBox(height: Responsive.h(8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(features.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: Responsive.symmetric(horizontal: 3),
              width: _currentIndex == index ? Responsive.w(15) : Responsive.w(5),
              height: Responsive.h(4),
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(Responsive.r(3)),
              ),
            );
          }),
        ),
      ],
    );
  }
}
