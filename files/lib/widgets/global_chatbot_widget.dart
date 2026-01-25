import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

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

class _DraggableChatbotWidgetState extends State<DraggableChatbotWidget> {
  Offset _chatButtonPosition = Offset(0, 0);
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      setState(() {
        _chatButtonPosition = widget.initialPosition ?? 
            Offset(size.width - Responsive.w(80), size.height - Responsive.h(110));
      });
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: FloatingActionButton(
            heroTag: widget.heroTag,
            onPressed: () {
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
    );
  }
}

