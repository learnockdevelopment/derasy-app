import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/assets.dart';
import '../core/utils/responsive_utils.dart';

class LoadingPage extends StatefulWidget {
  final String? title;
  final String? subtitle;

  const LoadingPage({
    Key? key,
    this.title,
    this.subtitle,
  }) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with SingleTickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _loadingAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.4),
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse Animation Background
                  AnimatedBuilder(
                    animation: _loadingAnimation,
                    builder: (context, child) {
                      return Container(
                        width: Responsive.w(120) * _loadingAnimation.value,
                        height: Responsive.w(120) * _loadingAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.blue1.withOpacity(
                            (0.15 * (1.2 - _loadingAnimation.value)).clamp(0.0, 1.0),
                          ),
                        ),
                      );
                    },
                  ),
                  ScaleTransition(
                    scale: _loadingAnimation,
                    child: Container(
                      width: Responsive.w(90),
                      height: Responsive.w(90),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue1.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(AssetsManager.logo, fit: BoxFit.contain),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(40)),
              Column(
                children: [
                  Text(
                    widget.title ?? 'loading'.tr,
                    style: TextStyle(
                      color: AppColors.blue1,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                      fontSize: Responsive.sp(18),
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    SizedBox(height: Responsive.h(8)),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: Responsive.sp(14),
                      ),
                    ),
                  ],
                  SizedBox(height: Responsive.h(16)),
                  Container(
                    width: Responsive.w(60),
                    height: Responsive.h(4),
                    decoration: BoxDecoration(
                      color: AppColors.blue1.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _loadingAnimation,
                          builder: (context, child) {
                            return Container(
                              width: (Responsive.w(60) * (_loadingAnimation.value - 0.8) * 5)
                                  .clamp(0.0, Responsive.w(60)),
                              decoration: BoxDecoration(
                                color: AppColors.blue1,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.blue1.withOpacity(0.3),
                                    blurRadius: 8,
                                  )
                                ],
                              ),
                            );
                          },
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
    );
  }
}
