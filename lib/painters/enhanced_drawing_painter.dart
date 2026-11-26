import 'package:material_ui/material_ui.dart';
import 'dart:ui' as ui;
import '../features/layers/models/layer_canvas_model.dart';

class EnhancedDrawingPainter extends CustomPainter {
  final Map<String, List<LayerStroke>> layerStrokes;
  final Map<String, double> layerOpacities;
  final Map<String, bool> layerVisibility;
  final Map<String, BlendMode> layerBlendModes;
  final List<String> layerOrder;
  final Size canvasSize;
  final Map<String, ui.Image?> layerCachedImages;
  final String? inProgressLayerId;
  final String? inProgressStrokeId;

  EnhancedDrawingPainter({
    required this.layerStrokes,
    required this.layerOpacities,
    required this.layerVisibility,
    required this.layerBlendModes,
    required this.layerOrder,
    this.canvasSize = const Size(1080, 2400),
    this.layerCachedImages = const {},
    this.inProgressLayerId,
    this.inProgressStrokeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw layers from bottom to top
    for (int i = layerOrder.length - 1; i >= 0; i--) {
      final layerId = layerOrder[i];

      // Skip hidden layers
      if (layerVisibility[layerId] == false) continue;

      final strokes = layerStrokes[layerId] ?? [];
      final opacity = layerOpacities[layerId] ?? 1.0;
      final blendMode = layerBlendModes[layerId] ?? BlendMode.srcOver;
      final cachedImage = layerCachedImages[layerId];

      _drawLayerToCanvas(
        canvas,
        layerId,
        strokes,
        opacity,
        blendMode,
        size,
        cachedImage,
      );
    }
  }

  void _drawLayerToCanvas(
    Canvas canvas,
    String layerId,
    List<LayerStroke> strokes,
    double opacity,
    BlendMode blendMode,
    Size size,
    ui.Image? cachedImage,
  ) {
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = Colors.black.withValues(alpha: opacity)
        ..blendMode = blendMode,
    );

    // Draw cached image first (all completed strokes)
    if (cachedImage != null) {
      canvas.drawImage(cachedImage, Offset.zero, Paint());
    }

    // Draw only the in-progress stroke live (if any)
    if (layerId == inProgressLayerId && inProgressStrokeId != null) {
      final inProgressStroke = strokes.cast<LayerStroke?>().lastWhere(
        (s) => s?.id == inProgressStrokeId,
        orElse: () => null,
      );
      
      if (inProgressStroke != null && inProgressStroke.points.isNotEmpty) {
        _drawStrokeToCanvas(canvas, inProgressStroke);
      }
    }

    canvas.restore();
  }

  void _drawStrokeToCanvas(Canvas canvas, LayerStroke stroke) {
    if (stroke.points.isEmpty) return;

    if (stroke.isEraser) {
      // Eraser stroke - uses BlendMode.clear to remove pixels
      final eraserPaint = Paint()
        ..color = Colors.transparent
        ..strokeWidth = stroke.strokeWidth
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high
        ..blendMode = BlendMode.clear;
      
      _renderStroke(canvas, stroke.points, eraserPaint);
    } else {
      // Normal stroke - blend with opacity and flow
      final finalAlpha = (stroke.opacity * stroke.flow).clamp(0.0, 1.0);
      final brushPaint = Paint()
        ..color = stroke.color.withValues(alpha: stroke.color.alpha * finalAlpha)
        ..strokeWidth = stroke.strokeWidth
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;
      
      _renderStroke(canvas, stroke.points, brushPaint);
    }
  }

  void _renderStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      canvas.drawCircle(points[0], paint.strokeWidth / 2, paint);
      return;
    }

    final path = _buildSmoothPath(points);

    // Set stroke properties
    paint
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  Path _buildSmoothPath(List<Offset> points) {
    final path = Path();
    
    if (points.isEmpty) return path;
    if (points.length == 1) {
      path.moveTo(points[0].dx, points[0].dy);
      return path;
    }

    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    for (int i = 1; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final midpoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, midpoint.dx, midpoint.dy);
    }

    path.lineTo(points[points.length - 1].dx, points[points.length - 1].dy);

    return path;
  }

  @override
  bool shouldRepaint(EnhancedDrawingPainter oldDelegate) {
    // Only repaint if in-progress stroke changed, or layer visibility/opacity changed
    if (oldDelegate.inProgressStrokeId != inProgressStrokeId ||
        oldDelegate.inProgressLayerId != inProgressLayerId) {
      return true;
    }
    
    if (oldDelegate.layerOpacities != layerOpacities ||
        oldDelegate.layerVisibility != layerVisibility ||
        oldDelegate.layerBlendModes != layerBlendModes ||
        oldDelegate.layerOrder != layerOrder) {
      return true;
    }
    
    // If only cached images changed, we don't need to repaint live
    return false;
  }
}


