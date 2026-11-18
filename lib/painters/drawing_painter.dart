import 'package:flutter/material.dart';
import '../models/drawing_models.dart';

class DrawingPainter extends CustomPainter {
  final List<DrawingLine> lines;
  final double activeLayerOpacity;

  DrawingPainter(this.lines, {this.activeLayerOpacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    for (final line in lines) {
      if (line.points.isEmpty) continue;

      if (line.isEraser) {
        final paint = Paint()
          ..strokeWidth = line.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.clear;

        _drawSmoothPath(canvas, line.points, paint);
      } else {
        // Apply layer opacity to stroke color
        final paint = Paint()
          ..color = Colors.black.withOpacity(activeLayerOpacity)
          ..strokeWidth = line.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        _drawSmoothPath(canvas, line.points, paint);
      }
    }
  }

  void _drawSmoothPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      canvas.drawCircle(points[0], paint.strokeWidth / 2, paint);
      return;
    }

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.lines.length != lines.length ||
        (lines.isNotEmpty &&
            oldDelegate.lines.isNotEmpty &&
            oldDelegate.lines.last.points.length != lines.last.points.length);
  }
}
