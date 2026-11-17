import 'package:flutter/material.dart';

class DrawingLine {
  final List<Offset> points;
  final bool isEraser;
  final Color color;
  final double strokeWidth;

  DrawingLine({
    required this.points,
    required this.isEraser,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
  });

  DrawingLine copyWith({List<Offset>? points}) {
    return DrawingLine(
      points: points ?? this.points,
      isEraser: isEraser,
      color: color,
      strokeWidth: strokeWidth,
    );
  }
}

class ReferenceImage {
  final String id;
  final String imagePath;
  final double scale;
  final double rotation;
  final double offsetX;
  final double offsetY;
  final double opacity;
  final double saturation;
  final bool isFlipped;
  final bool aspectRatioLocked;
  final int gridDivisions;
  final bool showGrid;

  ReferenceImage({
    required this.id,
    required this.imagePath,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.opacity = 1.0,
    this.saturation = 1.0,
    this.isFlipped = false,
    this.aspectRatioLocked = false,
    this.gridDivisions = 4,
    this.showGrid = false,
  });

  ReferenceImage copyWith({
    String? id,
    String? imagePath,
    double? scale,
    double? rotation,
    double? offsetX,
    double? offsetY,
    double? opacity,
    double? saturation,
    bool? isFlipped,
    bool? aspectRatioLocked,
    int? gridDivisions,
    bool? showGrid,
  }) {
    return ReferenceImage(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      opacity: opacity ?? this.opacity,
      saturation: saturation ?? this.saturation,
      isFlipped: isFlipped ?? this.isFlipped,
      aspectRatioLocked: aspectRatioLocked ?? this.aspectRatioLocked,
      gridDivisions: gridDivisions ?? this.gridDivisions,
      showGrid: showGrid ?? this.showGrid,
    );
  }
}

class DrawingState {
  final List<DrawingLine> lines;
  final bool isErasing;
  final double scale;
  final double rotation;
  final double offsetX;
  final double offsetY;
  final List<ReferenceImage> referenceImages;
  final int currentRefImageIndex;
  final bool isShowingReferenceImage;
  final bool isTransforming;

  DrawingState({
    required this.lines,
    required this.isErasing,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.referenceImages = const [],
    this.currentRefImageIndex = 0,
    this.isShowingReferenceImage = false,
    this.isTransforming = false,
  });

  ReferenceImage? get currentRefImage =>
      currentRefImageIndex >= 0 && currentRefImageIndex < referenceImages.length
          ? referenceImages[currentRefImageIndex]
          : null;

  DrawingState copyWith({
    List<DrawingLine>? lines,
    bool? isErasing,
    double? scale,
    double? rotation,
    double? offsetX,
    double? offsetY,
    List<ReferenceImage>? referenceImages,
    int? currentRefImageIndex,
    bool? isShowingReferenceImage,
    bool? isTransforming,
  }) {
    return DrawingState(
      lines: lines ?? this.lines,
      isErasing: isErasing ?? this.isErasing,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      referenceImages: referenceImages ?? this.referenceImages,
      currentRefImageIndex: currentRefImageIndex ?? this.currentRefImageIndex,
      isShowingReferenceImage: isShowingReferenceImage ?? this.isShowingReferenceImage,
      isTransforming: isTransforming ?? this.isTransforming,
    );
  }
}
