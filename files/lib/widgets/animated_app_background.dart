import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/controllers/app_config_controller.dart';

class AnimatedAppBackground extends StatefulWidget {
  final Widget child;
  const AnimatedAppBackground({Key? key, required this.child}) : super(key: key);

  @override
  State<AnimatedAppBackground> createState() => _AnimatedAppBackgroundState();
}

class _AnimatedAppBackgroundState extends State<AnimatedAppBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = AppConfigController.to.isDarkMode;

      final baseColors = isDark
          ? [
              const Color(0xFF0F172A),
              const Color(0xFF020617),
            ]
          : [
              const Color(0xFFEFF6FF),
              const Color(0xFFF8FAFC),
            ];

      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: baseColors,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: WavyBackgroundPainter(
                      animationValue: _controller.value,
                      isDark: isDark,
                    ),
                  ),
                ),
                widget.child,
              ],
            ),
          );
        },
      );
    });
  }
}

class WavyBackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  WavyBackgroundPainter({
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 3 bottom wave layers
    final bottomColors = isDark
        ? [
            const Color(0xFF3B82F6), // Blue
            const Color(0xFF8B5CF6), // Purple
            const Color(0xFF14B8A6), // Teal
          ]
        : [
            const Color(0xFF93C5FD), // Soft Blue
            const Color(0xFFC084FC), // Soft Purple
            const Color(0xFF99F6E4), // Soft Teal
          ];

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final double waveSpeed = (i + 1) * 0.45;
      final double phase = animationValue * 2 * math.pi * waveSpeed;
      final double amplitude = 22.0 + (i * 10.0);
      final double frequency = 0.0035 + (i * 0.0012);
      final double baseHeight = size.height * (0.75 + (i * 0.06));

      paint.color = bottomColors[i].withOpacity(isDark ? 0.06 : 0.07);

      path.moveTo(0, size.height);
      path.lineTo(0, baseHeight);

      for (double x = 0; x <= size.width; x += 8) {
        final double y = baseHeight + math.sin(x * frequency + phase) * amplitude;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }

    // 2 top wave layers
    final topColors = isDark
        ? [
            const Color(0xFF6366F1), // Indigo
            const Color(0xFF3B82F6), // Blue
          ]
        : [
            const Color(0xFFC7D2FE), // Soft Indigo
            const Color(0xFFBFDBFE), // Soft Blue
          ];

    for (int i = 0; i < 2; i++) {
      final path = Path();
      final double waveSpeed = (i + 1.2) * 0.35;
      final double phase = -animationValue * 2 * math.pi * waveSpeed;
      final double amplitude = 18.0 + (i * 12.0);
      final double frequency = 0.0045 + (i * 0.001);
      final double baseHeight = size.height * (0.12 + (i * 0.04));

      paint.color = topColors[i].withOpacity(isDark ? 0.05 : 0.06);

      path.moveTo(0, 0);
      path.lineTo(0, baseHeight);

      for (double x = 0; x <= size.width; x += 8) {
        final double y = baseHeight + math.cos(x * frequency + phase) * amplitude;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, 0);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WavyBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark;
  }
}
