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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    try {
      final box = Get.find<GetStorage>();
      box.write('has_seen_intro', true);
    } catch (_) {}
    Get.offNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final introData = [
      IntroData(
        title: 'welcome_to_kids_cottage'.tr,
        subtitle: 'nurturing_young_minds'.tr,
        image: AssetsManager.design1,
        planeImage: AssetsManager.design1,
        color: AppColors.primary,
        backgroundColor: AppColors.primary,
        shadowColor: AppColors.primary,
        isVertical: false,
      ),
      IntroData(
        title: 'expert_care'.tr,
        subtitle: 'care_description'.tr,
        image: AssetsManager.design2,
        planeImage: AssetsManager.design2,
        color: Color(0xFF2D5A87), // Medium blue to match design2
        backgroundColor: Color(0xFF2D5A87),
        shadowColor: Color(0xFF2D5A87),
        isVertical: false,
      ),
      IntroData(
        title: 'safe_environment'.tr,
        subtitle: 'safety_description'.tr,
        image: AssetsManager.design3,
        planeImage: AssetsManager.design3,
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
              setState(() {});
            },
            itemCount: introData.length,
            itemBuilder: (context, index) {
              final data = introData[index];
              final isLastPage = index == introData.length - 1;

              return IntroWidget(
                data: data,
                index: index,
                isLastPage: isLastPage,
                onNext: isLastPage
                    ? _goToLogin
                    : () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {});
        widget.onNext();
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final index = widget.index;
    final isLastPage = widget.isLastPage;
    return Container(
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
        children: [
          Positioned.fill(
            child: Image.asset(
              data.image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        data.color.withOpacity(0.8),
                        data.color.withOpacity(0.6),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Gradient overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
          // Main content - positioned lower
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Column(
                children: [
                  // Circular indicators above text
                  _CircularIndicator(
                    activeIndex: index,
                    count: widget.pageCount,
                  ),
                  SizedBox(height: 10.h),

                  // Title and subtitle - centered
                  Text(
                    data.title,
                    style: AppFonts.robotoBold24.copyWith(
                      color: AppColors.white,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    data.subtitle,
                    style: AppFonts.bodyLarge.copyWith(
                      color: AppColors.white.withOpacity(0.9),
                      height: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40.h),

                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 45.h,
                    child: ElevatedButton(
                      onPressed: widget.onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                      ),
                      child: Text(
                        isLastPage ? 'start_learning'.tr : 'next'.tr,
                        style: AppFonts.robotoBold16.copyWith(
                          color: AppColors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),

                  // Bottom spacing
                  SizedBox(height: 60.h),
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
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 6.w),
          width: isActive ? 12.w : 8.w,
          height: isActive ? 12.h : 8.h,
          decoration: BoxDecoration(
            color: isActive ? AppColors.selectedBlue : AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? AppColors.selectedBlue.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
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

class IntroData {
  final String title;
  final String subtitle;
  final String image;
  final String planeImage;
  final Color color;
  final Color backgroundColor;
  final Color shadowColor;
  final bool isVertical;

  IntroData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.planeImage,
    required this.color,
    required this.backgroundColor,
    required this.shadowColor,
    required this.isVertical,
  });
}
