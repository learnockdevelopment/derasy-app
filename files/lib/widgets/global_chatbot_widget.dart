import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_fonts.dart';

class DraggableChatbotWidget extends StatefulWidget {
  final Offset? initialPosition;
  final String? heroTag;
  
  const DraggableChatbotWidget({
    Key? key,
    this.initialPosition,
    this.heroTag,
  }) : super(key: key);

  @override
  State<DraggableChatbotWidget> createState() => _DraggableChatbotWidgetState();
}

class _DraggableChatbotWidgetState extends State<DraggableChatbotWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    // Show hint after a small delay, then hide after 5 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showHint = true);
        
        // Hide after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() => _showHint = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Hint Bubble
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: _showHint ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            if (value == 0 && !_showHint) return const SizedBox.shrink();
            return Positioned(
              right: Responsive.isRTL ? null : Responsive.w(70),
              left: Responsive.isRTL ? Responsive.w(70) : null,
              bottom: Responsive.h(12),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Transform.scale(
                    scale: value,
                    alignment: Responsive.isRTL ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      padding: Responsive.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(Responsive.r(20)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: AppColors.blue1.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (Responsive.isRTL)
                            Padding(
                              padding: Responsive.only(right: 4),
                              child: Icon(Icons.close_rounded, size: Responsive.sp(14), color: AppColors.grey400),
                            ),
                          Text(
                            'need_help_hint'.tr,
                            style: AppFonts.bodySmall.copyWith(
                              color: AppColors.blue1,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.sp(11),
                            ),
                          ),
                          if (!Responsive.isRTL)
                            Padding(
                              padding: Responsive.only(left: 4),
                              child: Icon(Icons.close_rounded, size: Responsive.sp(14), color: AppColors.grey400),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Main Button with Icon Pulse
        ScaleTransition(
          scale: _pulseAnimation,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: FloatingActionButton(
                  heroTag: widget.heroTag ?? 'chatbot_fab',
                  onPressed: () {
                    setState(() => _showHint = false);
                    Get.toNamed(AppRoutes.chatbot);
                  },
                  backgroundColor: AppColors.blue1,
                  elevation: 6,
                  child: Icon(
                    IconlyBold.chat,
                    color: Colors.white,
                    size: Responsive.sp(24),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

