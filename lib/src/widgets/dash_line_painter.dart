import 'package:flutter/material.dart';

class DashLinePainter extends CustomPainter {
  final Axis direction;
  final double dashLength;
  final double dashGap;
  final Color color;
  final double thickness;

  DashLinePainter({
    required this.direction,
    required this.color,
    this.dashLength = 4,
    this.dashGap = 4,
    this.thickness = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness;

    double start = 0;
    final max = direction == Axis.horizontal ? size.width : size.height;

    while (start < max) {
      final end = start + dashLength;

      if (direction == Axis.horizontal) {
        canvas.drawLine(
          Offset(start, 0),
          Offset(end, 0),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(0, start),
          Offset(0, end),
          paint,
        );
      }

      start += dashLength + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
