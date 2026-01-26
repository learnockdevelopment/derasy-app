import 'package:flutter/material.dart';

class HorizontalSwipeDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final double sensitivity;

  const HorizontalSwipeDetector({
    Key? key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.sensitivity = 1000.0, // Minimum velocity to trigger swipe
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity! > sensitivity) {
          // Swiping Right (Left to Right)
          onSwipeRight?.call();
        } else if (details.primaryVelocity! < -sensitivity) {
          // Swiping Left (Right to Left)
          onSwipeLeft?.call();
        }
      },
      child: child,
    );
  }
}
