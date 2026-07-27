import 'package:flutter/material.dart';

class FlyAnimation {
  static void run(
    BuildContext context, {
    required GlobalKey cartKey,
    required BuildContext buttonContext,
    required String imageUrl,
    required VoidCallback onComplete,
  }) {
    final overlay = Overlay.of(context);

    final RenderBox startBox = buttonContext.findRenderObject() as RenderBox;
    final startPos = startBox.localToGlobal(Offset.zero);
    final startSize = startBox.size;

    final RenderBox? endBox =
        cartKey.currentContext?.findRenderObject() as RenderBox?;
    if (endBox == null) {
      onComplete();
      return;
    }
    final endPos = endBox.localToGlobal(Offset.zero);
    final endSize = endBox.size;

    // Control point for Bezier curve (Parabolic path)
    // Mid-X, and Higher-Y (Start Y - 150) to create an arc
    final controlPointX = (startPos.dx + endPos.dx) / 2;
    final controlPointY = startPos.dy - 150;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _FlyingWidget(
          startPos: Offset(
            startPos.dx + startSize.width / 2 - 20,
            startPos.dy + startSize.height / 2 - 20,
          ),
          endPos: Offset(
            endPos.dx + endSize.width / 2 - 10,
            endPos.dy + endSize.height / 2 - 10,
          ),
          controlPoint: Offset(controlPointX, controlPointY),
          imageUrl: imageUrl,
          onComplete: () {
            entry.remove();
            onComplete();
          },
        );
      },
    );

    overlay.insert(entry);
  }
}

class _FlyingWidget extends StatefulWidget {
  final Offset startPos;
  final Offset endPos;
  final Offset controlPoint;
  final String imageUrl;
  final VoidCallback onComplete;

  const _FlyingWidget({
    required this.startPos,
    required this.endPos,
    required this.controlPoint,
    required this.imageUrl,
    required this.onComplete,
  });

  @override
  State<_FlyingWidget> createState() => _FlyingWidgetState();
}

class _FlyingWidgetState extends State<_FlyingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Use a custom curve for nicer acceleration/deceleration
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        // Quadratic Bezier Curve formula:
        // B(t) = (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
        final x = _calculateBezier(
          t,
          widget.startPos.dx,
          widget.controlPoint.dx,
          widget.endPos.dx,
        );
        final y = _calculateBezier(
          t,
          widget.startPos.dy,
          widget.controlPoint.dy,
          widget.endPos.dy,
        );

        // Scale down from 1.0 to 0.2 as it approaches cart
        final scale = 1.0 - (t * 0.8);
        // Rotate for effect
        final rotation = t * 2 * 3.14159;

        return Positioned(
          left: x,
          top: y,
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(widget.imageUrl),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateBezier(double t, double p0, double p1, double p2) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }
}
