import 'package:material_ui/material_ui.dart';

/// Represents a single stroke on a layer
class LayerStroke {
  final String id;
  final List<Offset> points;
  final bool isEraser;
  final Color color;
  final double strokeWidth;
  final double opacity;
  final double flow;

  LayerStroke({
    required this.id,
    required this.points,
    required this.isEraser,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.opacity = 1.0,
    this.flow = 1.0,
  });

  LayerStroke copyWith({
    String? id,
    List<Offset>? points,
    bool? isEraser,
    Color? color,
    double? strokeWidth,
    double? opacity,
    double? flow,
  }) {
    return LayerStroke(
      id: id ?? this.id,
      points: points ?? this.points,
      isEraser: isEraser ?? this.isEraser,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      flow: flow ?? this.flow,
    );
  }
}

/// Represents the canvas data for a single layer
class LayerCanvasData {
  final String layerId;
  final List<LayerStroke> strokes;

  LayerCanvasData({
    required this.layerId,
    this.strokes = const [],
  });

  LayerCanvasData copyWith({
    String? layerId,
    List<LayerStroke>? strokes,
  }) {
    return LayerCanvasData(
      layerId: layerId ?? this.layerId,
      strokes: strokes ?? this.strokes,
    );
  }

  /// Add a new stroke
  LayerCanvasData addStroke(LayerStroke stroke) {
    return copyWith(strokes: [...strokes, stroke]);
  }

  /// Remove a stroke by ID
  LayerCanvasData removeStroke(String strokeId) {
    return copyWith(
      strokes: strokes.where((s) => s.id != strokeId).toList(),
    );
  }

  /// Clear all strokes
  LayerCanvasData clear() {
    return copyWith(strokes: []);
  }

  /// Update a stroke
  LayerCanvasData updateStroke(String strokeId, List<Offset> newPoints) {
    return copyWith(
      strokes: strokes.map((s) {
        if (s.id == strokeId) {
          return s.copyWith(points: newPoints);
        }
        return s;
      }).toList(),
    );
  }

  /// Get the last stroke
  LayerStroke? getLastStroke() {
    return strokes.isEmpty ? null : strokes.last;
  }
}

/// Manages canvas data for all layers
class LayerCanvasStorage {
  final Map<String, LayerCanvasData> layerCanvasMap;

  LayerCanvasStorage({
    Map<String, LayerCanvasData>? layerCanvasMap,
  }) : layerCanvasMap = layerCanvasMap ?? {};

  /// Get canvas data for a specific layer
  LayerCanvasData getLayerCanvas(String layerId) {
    return layerCanvasMap[layerId] ??
        LayerCanvasData(layerId: layerId, strokes: []);
  }

  /// Set canvas data for a specific layer
  LayerCanvasStorage setLayerCanvas(
      String layerId, LayerCanvasData canvasData) {
    return LayerCanvasStorage(
      layerCanvasMap: {
        ...layerCanvasMap,
        layerId: canvasData,
      },
    );
  }

  /// Add a stroke to a layer
  LayerCanvasStorage addStrokeToLayer(String layerId, LayerStroke stroke) {
    final currentCanvas = getLayerCanvas(layerId);
    return setLayerCanvas(layerId, currentCanvas.addStroke(stroke));
  }

  /// Update a stroke on a layer
  LayerCanvasStorage updateStrokeOnLayer(
    String layerId,
    String strokeId,
    List<Offset> newPoints,
  ) {
    final currentCanvas = getLayerCanvas(layerId);
    return setLayerCanvas(
        layerId, currentCanvas.updateStroke(strokeId, newPoints));
  }

  /// Remove a stroke from a layer
  LayerCanvasStorage removeStrokeFromLayer(String layerId, String strokeId) {
    final currentCanvas = getLayerCanvas(layerId);
    return setLayerCanvas(layerId, currentCanvas.removeStroke(strokeId));
  }

  /// Clear all strokes from a layer
  LayerCanvasStorage clearLayerCanvas(String layerId) {
    final currentCanvas = getLayerCanvas(layerId);
    return setLayerCanvas(layerId, currentCanvas.clear());
  }

  /// Delete a layer's canvas (remove from storage)
  LayerCanvasStorage deleteLayerCanvas(String layerId) {
    final newMap = Map<String, LayerCanvasData>.from(layerCanvasMap)
      ..remove(layerId);
    return LayerCanvasStorage(layerCanvasMap: newMap);
  }

  /// Get all strokes from visible layers (for rendering)
  List<MapEntry<String, LayerStroke>> getAllVisibleStrokes(
    List<String> layerIds,
    Map<String, bool> layerVisibilityMap,
  ) {
    final result = <MapEntry<String, LayerStroke>>[];

    for (final layerId in layerIds) {
      if (layerVisibilityMap[layerId] != false) {
        final canvas = getLayerCanvas(layerId);
        for (final stroke in canvas.strokes) {
          result.add(MapEntry(layerId, stroke));
        }
      }
    }

    return result;
  }
}
