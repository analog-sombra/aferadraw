import 'package:material_ui/material_ui.dart';
import '../models/layer_model.dart';
import '../models/layer_canvas_model.dart';

/// Displays a preview of a layer's content
class LayerPreviewPainter extends CustomPainter {
  final List<LayerStroke> strokes;
  final double opacity;
  final bool fitToView;

  LayerPreviewPainter({
    required this.strokes,
    required this.opacity,
    this.fitToView = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    if (strokes.isEmpty) return;

    // Calculate bounds of all strokes
    Rect? strokeBounds;
    for (final stroke in strokes) {
      if (stroke.points.isNotEmpty) {
        for (final point in stroke.points) {
          final pointRect =
              Rect.fromCircle(center: point, radius: stroke.strokeWidth / 2);
          strokeBounds = strokeBounds?.expandToInclude(pointRect) ?? pointRect;
        }
      }
    }

    if (strokeBounds == null || strokeBounds.isEmpty) return;

    // Save and scale canvas if needed
    canvas.save();

    if (fitToView && (strokeBounds.width > 0 || strokeBounds.height > 0)) {
      // Calculate scale to fit content in preview with padding
      final padding = 4.0;
      final availableWidth = size.width - (padding * 2);
      final availableHeight = size.height - (padding * 2);

      final scaleX = availableWidth / strokeBounds.width;
      final scaleY = availableHeight / strokeBounds.height;
      final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.1, 1.0);

      // Translate and scale
      canvas.translate(padding, padding);
      canvas.translate(
        (availableWidth - strokeBounds.width * scale) / 2,
        (availableHeight - strokeBounds.height * scale) / 2,
      );
      canvas.scale(scale);
      canvas.translate(-strokeBounds.left, -strokeBounds.top);
    }

    // Draw strokes with opacity
    if (opacity < 1.0) {
      canvas.saveLayer(
        null,
        Paint()..color = Colors.black.withValues(alpha: opacity),
      );
    }

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, opacity);
    }

    if (opacity < 1.0) {
      canvas.restore();
    }

    canvas.restore();
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
      final paint = Paint()
        ..color = stroke.color.withValues(alpha: layerOpacity)
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
  bool shouldRepaint(LayerPreviewPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.opacity != opacity;
  }
}

/// Widget that displays a layer preview in a card
class LayerPreviewCard extends StatelessWidget {
  final Layer layer;
  final List<LayerStroke> strokes;
  final Offset position;

  const LayerPreviewCard({
    super.key,
    required this.layer,
    required this.strokes,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.deepPurple, width: 2),
          ),
          child: Column(
            children: [
              // Header with layer info
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[700]!),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      layer.type == 'group' ? Icons.folder : Icons.image,
                      color: layer.type == 'group'
                          ? Colors.amber
                          : Colors.grey[400],
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            layer.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Opacity: ${(layer.opacity * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Preview canvas
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: strokes.isEmpty
                      ? Center(
                          child: Text(
                            'Empty',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) => CustomPaint(
                            painter: LayerPreviewPainter(
                              strokes: strokes,
                              opacity: layer.opacity,
                            ),
                            size: Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay manager for showing layer preview
class LayerPreviewOverlay extends ChangeNotifier {
  Offset? _position;
  Layer? _layer;
  List<LayerStroke> _strokes = [];

  Offset? get position => _position;
  Layer? get layer => _layer;
  List<LayerStroke> get strokes => _strokes;

  void show({
    required Offset position,
    required Layer layer,
    required List<LayerStroke> strokes,
  }) {
    _position = position;
    _layer = layer;
    _strokes = strokes;
    notifyListeners();
  }

  void hide() {
    _position = null;
    _layer = null;
    _strokes = [];
    notifyListeners();
  }

  bool get isVisible => _position != null && _layer != null;
}
