import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/constants/app_colors.dart';

class AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;

  const AnimatedFAB({
    Key? key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.tooltip,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: widget.backgroundColor ?? AppColors.primaryBlue,
              tooltip: widget.tooltip,
              elevation: 8,
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: Responsive.sp(28),
              ),
            ),
          ),
        );
      },
    );
  }
}

