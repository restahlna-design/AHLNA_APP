import 'dart:math' as math;
import 'package:flutter/material.dart';

class MetallicRotatingPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  const MetallicRotatingPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final rect = Offset.zero & size;

    final colors = isDark
        ? const [
            Color(0xFFCBD5E1), // Steel silver
            Color(0xFFFFFFFF), // Brilliant chrome reflection
            Color(0xFF94A3B8), // Metallic slate
            Color(0xFF10B981), // Emerald green identity
            Color(0xFF34D399), // Emerald light sheen
            Color(0xFF059669), // Emerald deep shade
            Color(0xFF64748B), // Steel dark tone
            Color(0xFFFFFFFF), // Specular chrome highlight
            Color(0xFFCBD5E1), // Back to steel silver for seamless loop
          ]
        : const [
            Color(0xFF94A3B8), // Steel slate
            Color(0xFFFFFFFF), // Chrome white highlight
            Color(0xFFCBD5E1), // Platinum
            Color(0xFF10B981), // Emerald green identity
            Color(0xFF059669), // Rich emerald
            Color(0xFFCBD5E1), // Steel silver
            Color(0xFFFFFFFF), // Brilliant chrome specular reflection
            Color(0xFF94A3B8), // Loop closure
          ];

    final stops = isDark
        ? const [0.0, 0.12, 0.25, 0.42, 0.52, 0.64, 0.76, 0.88, 1.0]
        : const [0.0, 0.14, 0.28, 0.45, 0.58, 0.72, 0.86, 1.0];

    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: colors,
        stops: stops,
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant MetallicRotatingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
