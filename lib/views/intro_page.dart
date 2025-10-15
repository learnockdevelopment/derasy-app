import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../core/routes/app_routes.dart';
import '../core/constants/assets.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({Key? key}) : super(key: key);

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<IntroData> _introData = [
    IntroData(
      title: 'book_dream_flights'.tr,
      image: AssetsManager.design1,
      color: AppColors.primary,
      backgroundColor: AppColors.orange50,
      isVertical: true,
    ),
    IntroData(
      title: 'find_perfect_stay'.tr,
      image: AssetsManager.design2,
      color: AppColors.secondary,
      backgroundColor: AppColors.blue50,
      isVertical: false,
    ),
    IntroData(
      title: 'apply_visa_easily'.tr,
      image: AssetsManager.design3,
      color: AppColors.deepOrange500,
      backgroundColor: AppColors.green50,
      isVertical: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _introData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Get.offNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: EdgeInsets.only(top: 20.h, right: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _goToLogin,
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    ),
                    child: Text(
                      'skip'.tr,
                      style: AppFonts.buttonMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _introData.length,
                itemBuilder: (context, index) {
                  return IntroWidget(
                    data: _introData[index],
                    index: index,
                    isLastPage: index == _introData.length - 1,
                    onNext: _nextPage,
                  );
                },
              ),
            ),
            // Page indicator
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _introData.length,
                effect: WormEffect(
                  dotColor: AppColors.grey300,
                  activeDotColor: _introData[_currentPage].color,
                  dotHeight: 10.h,
                  dotWidth: 10.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IntroWidget extends StatelessWidget {
  final IntroData data;
  final int index;
  final bool isLastPage;
  final VoidCallback onNext;

  const IntroWidget({
    Key? key,
    required this.data,
    required this.index,
    required this.isLastPage,
    required this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          // Main content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image with colored background and floating elements
                Container(
                  width: 350.w,
                  height: 350.h,
                  decoration: BoxDecoration(
                    color: data.backgroundColor,
                    borderRadius: BorderRadius.circular(30.r),
                    boxShadow: [
                      BoxShadow(
                        color: data.backgroundColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Main image
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.w),
                          child: Image.asset(
                            data.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.flight,
                                size: 120.w,
                                color: data.color,
                              );
                            },
                          ),
                        ),
                      ),
                      // Floating elements
                      if (index == 0) ...[
                        // Flight page floating elements
                        Positioned(
                          top: 40.h,
                          left: 20.w,
                          child: Container(
                            width: 40.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.flight,
                              color: AppColors.primary,
                              size: 20.w,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 80.h,
                          right: 30.w,
                          child: Container(
                            width: 30.w,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: AppColors.blue100,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 60.h,
                          left: 30.w,
                          child: Container(
                            width: 25.w,
                            height: 15.h,
                            decoration: BoxDecoration(
                              color: AppColors.blue100,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ] else if (index == 1) ...[
                        // Stays page floating elements
                        Positioned(
                          top: 50.h,
                          right: 20.w,
                          child: Container(
                            width: 35.w,
                            height: 35.h,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.hotel,
                              color: AppColors.secondary,
                              size: 18.w,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 80.h,
                          left: 25.w,
                          child: Container(
                            width: 30.w,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: AppColors.orange100,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Visa page floating elements
                        Positioned(
                          top: 60.h,
                          left: 20.w,
                          child: Container(
                            width: 40.w,
                            height: 25.h,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(6.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.credit_card,
                              color: AppColors.deepOrange500,
                              size: 16.w,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 70.h,
                          right: 25.w,
                          child: Container(
                            width: 35.w,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: AppColors.green100,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 50.h),
                // Title
                Text(
                  data.title,
                  style: AppFonts.robotoBold28.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 50.h),
                // Next/Get Started button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: data.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isLastPage ? 'start_journey'.tr : 'next'.tr,
                      style: AppFonts.robotoBold16.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IntroData {
  final String title;
  final String image;
  final Color color;
  final Color backgroundColor;
  final bool isVertical;

  IntroData({
    required this.title,
    required this.image,
    required this.color,
    required this.backgroundColor,
    required this.isVertical,
  });
}
