import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart'; 

class PromotionalBannerWidget extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final String? actionButtonText;
  final IconData? actionButtonIcon;
  final VoidCallback? onActionTap;
  final double? height;
  
  const PromotionalBannerWidget({
    Key? key,
    this.title,
    this.subtitle,
    this.icon,
    this.actionButtonText,
    this.actionButtonIcon,
    this.onActionTap,
    this.height,
  }) : super(key: key);

  @override
  State<PromotionalBannerWidget> createState() => _PromotionalBannerWidgetState();
}

class _PromotionalBannerWidgetState extends State<PromotionalBannerWidget>
    with TickerProviderStateMixin {
  late AnimationController _bannerAnimationController;
  late AnimationController _floatingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _floatingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bannerAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _bannerAnimationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _bannerAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    _bannerAnimationController.forward();
  }
  
  @override
  void dispose() {
    _bannerAnimationController.dispose();
    _floatingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bannerAnimationController,
      builder: (context, child) {
        return Container(
          height: widget.height ?? 140.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.blue1,
                AppColors.blue1.withOpacity(0.9),
                AppColors.blue2.withOpacity(0.85),
                AppColors.blue2.withOpacity(0.75),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
            borderRadius: BorderRadius.circular(32.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue1.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 12),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Animated decorative circles
              AnimatedBuilder(
                animation: _floatingAnimationController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Large top-right circle with floating animation
                      Positioned(
                        top: -50.h + (10 * math.sin(_floatingAnimationController.value * 2 * math.pi)),
                        right: -50.w + (8 * math.cos(_floatingAnimationController.value * 2 * math.pi)),
                        child: Opacity(
                          opacity: _fadeAnimation.value * 0.2,
                          child: Container(
                            width: 160.w,
                            height: 160.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.05),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Medium bottom-left circle
                      Positioned(
                        bottom: -40.h + (8 * math.cos(_floatingAnimationController.value * 2 * math.pi)),
                        left: -40.w + (6 * math.sin(_floatingAnimationController.value * 2 * math.pi)),
                        child: Opacity(
                          opacity: _fadeAnimation.value * 0.15,
                          child: Container(
                            width: 120.w,
                            height: 120.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.05),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Small top-right circle
                      Positioned(
                        top: 25.h + (5 * math.sin(_floatingAnimationController.value * 2 * math.pi + math.pi / 2)),
                        right: 25.w + (4 * math.cos(_floatingAnimationController.value * 2 * math.pi + math.pi / 2)),
                        child: Opacity(
                          opacity: _fadeAnimation.value * 0.25,
                          child: Container(
                            width: 70.w,
                            height: 70.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Additional small decorative circle
                      Positioned(
                        bottom: 30.h + (6 * math.cos(_floatingAnimationController.value * 2 * math.pi)),
                        right: 40.w + (5 * math.sin(_floatingAnimationController.value * 2 * math.pi)),
                        child: Opacity(
                          opacity: _fadeAnimation.value * 0.2,
                          child: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Animated content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Welcome badge with animation
                          if (widget.subtitle != null)
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (widget.icon != null)
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            duration: const Duration(milliseconds: 600),
                                            curve: Curves.elasticOut,
                                            builder: (context, rotateValue, child) {
                                              return Transform.rotate(
                                                angle: rotateValue * 0.2,
                                                child: Icon(
                                                  widget.icon,
                                                  color: Colors.white,
                                                  size: 16.sp,
                                                ),
                                              );
                                            },
                                          ),
                                        if (widget.icon != null) SizedBox(width: 6.w),
                                        Text(
                                          widget.subtitle!,
                                          style: AppFonts.bodySmall.copyWith(
                                            color: Colors.white,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (widget.subtitle != null) SizedBox(height: 10.h),
                          // Main title with button on right
                          if (widget.title != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Title text first
                                Expanded(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 1000),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 15 * (1 - value)),
                                          child: Text(
                                            widget.title!,
                                            style: AppFonts.h3.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18.sp,
                                              letterSpacing: 0.3,
                                              height: 1.3,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  offset: const Offset(0, 2),
                                                  blurRadius: 4,
                                                ),
                                                Shadow(
                                                  color: Colors.white.withOpacity(0.1),
                                                  offset: const Offset(0, 1),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Space
                                if (widget.actionButtonText != null && widget.onActionTap != null)
                                  SizedBox(width: 12.w),
                                // Action Button on right
                                if (widget.actionButtonText != null && widget.onActionTap != null)
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 1200),
                                    curve: Curves.elasticOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: widget.onActionTap,
                                            borderRadius: BorderRadius.circular(12.r),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12.r),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.white.withOpacity(0.3),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (widget.actionButtonIcon != null) ...[
                                                    Icon(
                                                      widget.actionButtonIcon,
                                                      color: AppColors.blue1,
                                                      size: 16.sp,
                                                    ),
                                                    SizedBox(width: 6.w),
                                                  ],
                                                  Text(
                                                    widget.actionButtonText!,
                                                    style: AppFonts.bodyMedium.copyWith(
                                                      color: AppColors.blue1,
                                                      fontSize: 12.sp,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.2,
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
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


