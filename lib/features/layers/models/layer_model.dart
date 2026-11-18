import 'package:flutter/material.dart';

class Layer {
  final String id;
  final String name;
  final double opacity;
  final bool isVisible;
  final bool isLocked;
  final String type; // 'basic' or 'group'
  final List<String> childLayerIds;
  final String? parentId; // Reference to parent group layer
  final BlendMode blendMode;

  Layer({
    required this.id,
    required this.name,
    this.opacity = 1.0,
    this.isVisible = true,
    this.isLocked = false,
    this.type = 'basic',
    List<String>? childLayerIds,
    this.parentId,
    this.blendMode = BlendMode.srcOver,
  }) : childLayerIds = childLayerIds ?? const [];

  Layer copyWith({
    String? id,
    String? name,
    double? opacity,
    bool? isVisible,
    bool? isLocked,
    String? type,
    List<String>? childLayerIds,
    String? parentId,
    BlendMode? blendMode,
  }) {
    return Layer(
      id: id ?? this.id,
      name: name ?? this.name,
      opacity: opacity ?? this.opacity,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      type: type ?? this.type,
      childLayerIds: childLayerIds ?? this.childLayerIds,
      parentId: parentId ?? this.parentId,
      blendMode: blendMode ?? this.blendMode,
    );
  }
}

class LayerStack {
  final List<Layer> layers;
  final int activeLayerIndex;

  LayerStack({
    required this.layers,
    required this.activeLayerIndex,
  });

  Layer? get activeLayer =>
      activeLayerIndex >= 0 && activeLayerIndex < layers.length
          ? layers[activeLayerIndex]
          : null;

  LayerStack copyWith({
    List<Layer>? layers,
    int? activeLayerIndex,
  }) {
    return LayerStack(
      layers: layers ?? this.layers,
      activeLayerIndex: activeLayerIndex ?? this.activeLayerIndex,
    );
  }
}
