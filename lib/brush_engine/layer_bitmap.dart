import 'package:material_ui/material_ui.dart';
import 'dart:ui' as ui;
import '../features/layers/models/layer_canvas_model.dart';
import 'smooth_brush_renderer.dart';

/// Layer bitmap for pixel-perfect rendering
/// Stores rendered strokes as a picture buffer
class LayerBitmap {
  final String layerId;
  final double width;
  final double height;
  ui.Picture? _picture;
  final List<LayerStroke> strokes;

  LayerBitmap({
    required this.layerId,
    required this.width,
    required this.height,
    this.strokes = const [],
  });

  /// Render all strokes to a picture
  void renderToBuffer() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.transparent,
    );

    // Draw each stroke
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      if (stroke.isEraser) {
        // Eraser: use dstOut to remove pixels
        final eraserPaint = PixelBrushRenderer.createEraserPaint(stroke.strokeWidth);
        _drawStrokeToCanvas(canvas, stroke, eraserPaint);
      } else {
        // Brush: draw with color
        final brushPaint = PixelBrushRenderer.createBrushPaint(
          color: stroke.color,
          strokeWidth: stroke.strokeWidth,
          opacity: stroke.opacity * stroke.flow,
        );
        _drawStrokeToCanvas(canvas, stroke, brushPaint);
      }
    }

    _picture = recorder.endRecording();
  }

  /// Draw a single stroke to canvas
  void _drawStrokeToCanvas(Canvas canvas, LayerStroke stroke, Paint paint) {
    if (stroke.points.isEmpty) return;

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points[0], paint.strokeWidth / 2, paint);
      return;
    }

    final path = Path();
    path.moveTo(stroke.points[0].dx, stroke.points[0].dy);

    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }

    paint
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  /// Get the rendered picture
  ui.Picture? getPicture() => _picture;

  /// Create a copy with new strokes
  LayerBitmap copyWith({List<LayerStroke>? strokes}) {
    return LayerBitmap(
      layerId: layerId,
      width: width,
      height: height,
      strokes: strokes ?? this.strokes,
    );
  }
}
