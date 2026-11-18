import 'package:flutter/material.dart';
import '../features/layers/models/layer_canvas_model.dart';

class EnhancedDrawingPainter extends CustomPainter {
  final Map<String, List<LayerStroke>> layerStrokes;
  final Map<String, double> layerOpacities;
  final Map<String, bool> layerVisibility;
  final Map<String, BlendMode> layerBlendModes;
  final List<String> layerOrder;

  EnhancedDrawingPainter({
    required this.layerStrokes,
    required this.layerOpacities,
    required this.layerVisibility,
    required this.layerBlendModes,
    required this.layerOrder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw layers from bottom to top (reverse order)
    for (int i = layerOrder.length - 1; i >= 0; i--) {
      final layerId = layerOrder[i];
      
      // Skip hidden layers
      if (layerVisibility[layerId] == false) continue;

      final strokes = layerStrokes[layerId] ?? [];
      final opacity = layerOpacities[layerId] ?? 1.0;
      final blendMode = layerBlendModes[layerId] ?? BlendMode.srcOver;

      // Apply opacity and blend mode to entire layer
      if (opacity < 1.0 || blendMode != BlendMode.srcOver) {
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()
            ..color = Colors.black.withOpacity(opacity)
            ..blendMode = blendMode,
        );
      }

      // Draw all strokes on this layer
      for (final stroke in strokes) {
        _drawStroke(canvas, stroke, opacity);
      }

      if (opacity < 1.0 || blendMode != BlendMode.srcOver) {
        canvas.restore();
      }
    }
  }

  void _drawStroke(Canvas canvas, LayerStroke stroke, double layerOpacity) {
    if (stroke.points.isEmpty) return;

    if (stroke.isEraser) {
      final paint = Paint()
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = BlendMode.clear;

      _drawSmoothPath(canvas, stroke.points, paint);
    } else {
      // Apply layer opacity to stroke color
      final paint = Paint()
        ..color = stroke.color.withOpacity(layerOpacity)
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      _drawSmoothPath(canvas, stroke.points, paint);
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
  bool shouldRepaint(EnhancedDrawingPainter oldDelegate) {
    // Repaint if layer strokes, opacities, visibility, blend modes, or order changed
    return oldDelegate.layerStrokes != layerStrokes ||
        oldDelegate.layerOpacities != layerOpacities ||
        oldDelegate.layerVisibility != layerVisibility ||
        oldDelegate.layerBlendModes != layerBlendModes ||
        oldDelegate.layerOrder != layerOrder;
  }
}
