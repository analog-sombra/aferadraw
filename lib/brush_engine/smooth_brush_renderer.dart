import 'package:material_ui/material_ui.dart';
import 'dart:ui' as ui;

/// Pixel-based brush renderer using image recording and rendering
/// Draws strokes to actual bitmap images for true pixel-level erasing
class PixelBrushRenderer {
  /// Records a stroke to a picture (bitmap equivalent)
  static ui.Picture recordStrokeToPicture(
    List<Offset> points,
    Paint paint,
    Size canvasSize,
  ) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    if (points.isNotEmpty) {
      if (points.length == 1) {
        canvas.drawCircle(points[0], paint.strokeWidth / 2, paint);
      } else {
        // Draw solid path connecting all points
        final path = Path();
        path.moveTo(points[0].dx, points[0].dy);

        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }

        // Configure paint for stroke
        paint
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true;

        canvas.drawPath(path, paint);
      }
    }

    return recorder.endRecording();
  }

  /// Creates eraser paint for pixel removal
  static Paint createEraserPaint(double strokeWidth) {
    return Paint()
      ..strokeWidth = strokeWidth
      ..color = Colors.transparent
      ..blendMode = BlendMode.dstOut
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;
  }

  /// Creates brush paint for drawing
  static Paint createBrushPaint({
    required Color color,
    required double strokeWidth,
    required double opacity,
  }) {
    return Paint()
      ..color = color.withValues(alpha: color.alpha * opacity)
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;
  }
}
