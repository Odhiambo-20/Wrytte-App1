import 'dart:math' as math;
import 'package:flutter/material.dart';

class TickRing extends StatelessWidget {
  const TickRing({
    super.key,
    required this.size,
    required this.child,
    this.tickCount = 60,
    this.tickWidth = 3,
    this.tickLength = 12,
    this.gap = 8,
    this.tickColor = Colors.white,
    this.activeTickColor = const Color(0xFF00E676),
    this.activeTickFraction = 0.0,
  });

  final double size;
  final Widget child;
  final int tickCount;
  final double tickWidth;
  final double tickLength;
  final double gap;
  final Color tickColor;
  final Color activeTickColor;
  final double activeTickFraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _TickRingPainter(
              tickCount: tickCount,
              tickWidth: tickWidth,
              tickLength: tickLength,
              gap: gap,
              tickColor: tickColor,
              activeTickColor: activeTickColor,
              activeTickFraction: activeTickFraction,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _TickRingPainter extends CustomPainter {
  _TickRingPainter({
    required this.tickCount,
    required this.tickWidth,
    required this.tickLength,
    required this.gap,
    required this.tickColor,
    required this.activeTickColor,
    required this.activeTickFraction,
  });

  final int tickCount;
  final double tickWidth;
  final double tickLength;
  final double gap;
  final Color tickColor;
  final Color activeTickColor;
  final double activeTickFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - tickLength;
    final activeTicks = (activeTickFraction * tickCount).round();

    for (int i = 0; i < tickCount; i++) {
      final paint = Paint()
        ..color = i < activeTicks ? activeTickColor : tickColor
        ..strokeWidth = tickWidth
        ..strokeCap = StrokeCap.round;

      final angle = (2 * math.pi / tickCount) * i - math.pi / 2;
      final outer = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      final inner = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TickRingPainter oldDelegate) {
    return oldDelegate.activeTickFraction != activeTickFraction ||
        oldDelegate.activeTickColor != activeTickColor ||
        oldDelegate.tickColor != tickColor;
  }
}
