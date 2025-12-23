import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

class GlobalChatbotWidget extends StatefulWidget {
  const GlobalChatbotWidget({Key? key}) : super(key: key);

  @override
  State<GlobalChatbotWidget> createState() => _GlobalChatbotWidgetState();
}

class _GlobalChatbotWidgetState extends State<GlobalChatbotWidget> {
  // Draggable position (stored as offset from screen edges)
  double _leftOffset = 0.0;
  double _topOffset = 0.0;
  bool _isInitialized = false;
  bool _isDragging = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final screenSize = MediaQuery.of(context).size;
      // Initialize to bottom-right corner
      _leftOffset = screenSize.width - 56.w - 20.0;
      _topOffset = screenSize.height - 56.h - 20.0;
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Update position if screen size changes
    if (_isInitialized) {
      _leftOffset = _leftOffset.clamp(0.0, screenSize.width - 56.w);
      _topOffset = _topOffset.clamp(0.0, screenSize.height - 56.h);
    }
    
    return Positioned(
      left: _leftOffset,
      top: _topOffset,
      child: GestureDetector(
        onPanStart: (details) {
          _isDragging = false;
        },
        onPanUpdate: (details) {
          _isDragging = true;
          setState(() {
            _leftOffset = (_leftOffset + details.delta.dx).clamp(0.0, screenSize.width - 56.w);
            _topOffset = (_topOffset + details.delta.dy).clamp(0.0, screenSize.height - 56.h);
          });
        },
        onPanEnd: (details) {
          _isDragging = false;
        },
        onTap: () {
          // Only navigate if not dragging
          if (!_isDragging) {
            Get.toNamed(AppRoutes.chatbot);
          }
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 56.w,
            height: 56.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
        ),
      ),
    );
  }
}
