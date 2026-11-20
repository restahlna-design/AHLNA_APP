import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter for the rotating metallic border effect.
/// Uses [RepaintBoundary] in the widget tree for optimal Impeller rendering.
class MetallicRotatingPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  MetallicRotatingPainter({
    required this.progress,
    required this.isDark,
  });

  // Pre-computed color lists (not const to avoid issues with tree-shaking)
  static final List<Color> _darkColors = [
    const Color(0xFFCBD5E1), // Steel silver
    const Color(0xFFFFFFFF), // Brilliant chrome reflection
    const Color(0xFF94A3B8), // Metallic slate
    const Color(0xFF10B981), // Emerald green identity
    const Color(0xFF34D399), // Emerald light sheen
    const Color(0xFF059669), // Emerald deep shade
    const Color(0xFF64748B), // Steel dark tone
    const Color(0xFFFFFFFF), // Specular chrome highlight
    const Color(0xFFCBD5E1), // Back to steel silver for seamless loop
  ];

  static final List<Color> _lightColors = [
    const Color(0xFF94A3B8), // Steel slate
    const Color(0xFFFFFFFF), // Chrome white highlight
    const Color(0xFFCBD5E1), // Platinum
    const Color(0xFF10B981), // Emerald green identity
    const Color(0xFF059669), // Rich emerald
    const Color(0xFFCBD5E1), // Steel silver
    const Color(0xFFFFFFFF), // Brilliant chrome specular reflection
    const Color(0xFF94A3B8), // Loop closure
  ];

  static const List<double> _darkStops = [0.0, 0.12, 0.25, 0.42, 0.52, 0.64, 0.76, 0.88, 1.0];
  static const List<double> _lightStops = [0.0, 0.14, 0.28, 0.45, 0.58, 0.72, 0.86, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final colors = isDark ? _darkColors : _lightColors;
    final stops = isDark ? _darkStops : _lightStops;

    final shader = SweepGradient(
      center: Alignment.center,
      colors: colors,
      stops: stops,
      transform: GradientRotation(progress * 2 * math.pi),
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant MetallicRotatingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
