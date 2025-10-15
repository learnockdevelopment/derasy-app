import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({Key? key}) : super(key: key);

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isNavigating = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      final box = Get.find<GetStorage>();
      box.write('has_seen_intro', true);
      print('✅ Intro completed, navigating to login');
    } catch (e) {
      print('❌ Error saving intro state: $e');
    }

    // Add a small delay to ensure state is saved
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        Get.offNamed(AppRoutes.login);
        print('✅ Successfully navigated to login page');
      } catch (e) {
        print('❌ Error navigating to login: $e');
        _isNavigating = false; // Reset navigation flag on error
      }
    });
  }

  void _goToNextPage() {
    if (_isNavigating) return;

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final introData = [
      IntroData(
        title: 'welcome_to_kids_cottage'.tr,
        subtitle: 'nurturing_young_minds'.tr,
        image: AssetsManager.design2,
        color: AppColors.primary,
        backgroundColor: AppColors.primary,
        shadowColor: AppColors.primary,
        isVertical: false,
      ),
      IntroData(
        title: 'expert_care'.tr,
        subtitle: 'care_description'.tr,
        image: AssetsManager.design1,
        color: Color(0xFF2D5A87), // Medium blue to match design2
        backgroundColor: Color(0xFF2D5A87),
        shadowColor: Color(0xFF2D5A87),
        isVertical: false,
      ),
      IntroData(
        title: 'safe_environment'.tr,
        subtitle: 'safety_description'.tr,
        image: AssetsManager.design3,
        color: Color(0xFF0F2F4A), // Darker blue to match design3
        backgroundColor: Color(0xFF0F2F4A),
        shadowColor: Color(0xFF0F2F4A),
        isVertical: false,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: introData.length,
            itemBuilder: (context, index) {
              final data = introData[index];
              final isLastPage = index == introData.length - 1;

              return IntroWidget(
                data: data,
                index: index,
                isLastPage: isLastPage,
                onNext: _goToNextPage,
                pageController: _pageController,
                pageCount: introData.length,
              );
            },
          ),
          // Skip button overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 20.h,
            right: 20.w,
            child: TextButton(
              onPressed: _goToLogin,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
              child: Text(
                'skip'.tr,
                style: AppFonts.buttonMedium.copyWith(
                  color: AppColors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IntroWidget extends StatefulWidget {
  final IntroData data;
  final int index;
  final bool isLastPage;
  final VoidCallback onNext;
  final PageController pageController;
  final int pageCount;

  const IntroWidget({
    Key? key,
    required this.data,
    required this.index,
    required this.isLastPage,
    required this.onNext,
    required this.pageController,
    required this.pageCount,
  }) : super(key: key);

  @override
  State<IntroWidget> createState() => _IntroWidgetState();
}

class _IntroWidgetState extends State<IntroWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start animation immediately without delay
    if (!_isDisposed && mounted) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(IntroWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset animation state when widget updates (page changes)
    if (oldWidget.index != widget.index) {
      _restartAnimation();
    }
  }

  void _restartAnimation() {
    _controller.reset();
    // Restart animation for new page immediately
    if (!_isDisposed && mounted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final index = widget.index;
    final isLastPage = widget.isLastPage;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            data.backgroundColor.withOpacity(0.15),
            AppColors.background,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * _controller.value),
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _controller.value)),
                    child: Opacity(
                      opacity: _controller.value,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: widget.data.color.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: Image.asset(
                            widget.data.image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            gaplessPlayback: true,
                            isAntiAlias: true,
                            filterQuality: FilterQuality.high,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) {
                              print(
                                  '❌ Image loading error for ${widget.data.image}: $error');
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      widget.data.color.withOpacity(0.8),
                                      widget.data.color.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.child_care,
                                        size: 80.w,
                                        color: AppColors.white.withOpacity(0.8),
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        'Welcome to Kids Cottage',
                                        style: AppFonts.robotoBold20.copyWith(
                                          color:
                                              AppColors.white.withOpacity(0.9),
                                          fontSize: 20.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Subtle overlay for better visual appeal
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.2),
                  ],
                  stops: [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),
          // Enhanced gradient overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: [0.0, 0.3, 0.6, 0.8, 1.0],
                ),
              ),
            ),
          ),
          // Main content - positioned lower with better spacing
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(30.w, 20.h, 30.w, 40.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circular indicators above text
                  _CircularIndicator(
                    activeIndex: index,
                    count: widget.pageCount,
                  ),
                  SizedBox(height: 30.h),

                  // Title and subtitle - centered with better spacing
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Column(
                      children: [
                        Text(
                          data.title,
                          style: AppFonts.robotoBold24.copyWith(
                            color: AppColors.white,
                            height: 1.3,
                            fontSize: 28
                                .sp
                                .clamp(20.sp, 32.sp), // Responsive font size
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.7),
                                offset: Offset(0, 2),
                                blurRadius: 6,
                              ),
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          data.subtitle,
                          style: AppFonts.bodyLarge.copyWith(
                            color: AppColors.white.withOpacity(0.95),
                            height: 1.6,
                            fontSize: 16
                                .sp
                                .clamp(14.sp, 18.sp), // Responsive font size
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 50.h),

                  // Next/Get Started button with enhanced design
                  Container(
                    width: double.infinity,
                    height: 50.h.clamp(45.h, 55.h), // Responsive height
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          offset: Offset(0, 4),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_isDisposed && mounted) {
                          widget.onNext();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                      ),
                      child: Text(
                        isLastPage ? 'start_learning'.tr : 'next'.tr,
                        style: AppFonts.robotoBold16.copyWith(
                          color: AppColors.white,
                          fontSize:
                              16.sp.clamp(14.sp, 18.sp), // Responsive font size
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Bottom spacing
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroIndicator extends StatelessWidget {
  final int activeIndex;
  final int count;

  const _IntroIndicator(
      {Key? key, required this.activeIndex, required this.count})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: isActive ? 24.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.selectedBlue
                : AppColors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? AppColors.selectedBlue.withOpacity(0.3)
                    : Colors.black.withOpacity(0.2),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _CircularIndicator extends StatelessWidget {
  final int activeIndex;
  final int count;

  const _CircularIndicator(
      {Key? key, required this.activeIndex, required this.count})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          width: isActive ? 16.w : 10.w,
          height: isActive ? 16.h : 10.h,
          decoration: BoxDecoration(
            color:
                isActive ? AppColors.white : AppColors.white.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? AppColors.primary.withOpacity(0.4)
                    : Colors.black.withOpacity(0.2),
                offset: Offset(0, 3),
                blurRadius: isActive ? 8 : 4,
                spreadRadius: isActive ? 1 : 0,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class IntroData {
  final String title;
  final String subtitle;
  final String image;
  final Color color;
  final Color backgroundColor;
  final Color shadowColor;
  final bool isVertical;

  IntroData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.color,
    required this.backgroundColor,
    required this.shadowColor,
    required this.isVertical,
  });
}
