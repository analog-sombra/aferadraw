import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' show max;
import 'dart:ui' as ui;
import '../models/drawing_models.dart';
import '../features/layers/models/layer_canvas_model.dart';
import '../features/color_picker/providers/color_picker_provider.dart';
import '../features/brush/providers/brush_provider.dart';
import '../drawing/stroke_stabilizer.dart';

/// Per-layer raster cache for performance
class LayerRasterCache {
  final String layerId;
  ui.Image? cachedImage;
  
  LayerRasterCache({required this.layerId});
  
  /// Dispose old image if it exists
  void dispose() {
    cachedImage?.dispose();
    cachedImage = null;
  }
  
  /// Update cache with new image
  void updateCache(ui.Image? newImage) {
    dispose();
    cachedImage = newImage;
  }
}

/// Enhanced drawing state that includes per-layer canvas data
class EnhancedDrawingState {
  final double scale;
  final double rotation;
  final double offsetX;
  final double offsetY;
  final bool isErasing;
  final List<ReferenceImage> referenceImages;
  final int currentRefImageIndex;
  final bool isShowingReferenceImage;
  final bool isTransforming;
  final bool isRefImageDrawMode;

  // Layer canvas storage
  final LayerCanvasStorage layerCanvasStorage;
  
  // Per-layer raster caches
  final Map<String, LayerRasterCache> layerRasterCaches;

  EnhancedDrawingState({
    this.scale = 1.0,
    this.rotation = 0.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.isErasing = false,
    this.referenceImages = const [],
    this.currentRefImageIndex = 0,
    this.isShowingReferenceImage = false,
    this.isTransforming = false,
    this.isRefImageDrawMode = false,
    LayerCanvasStorage? layerCanvasStorage,
    Map<String, LayerRasterCache>? layerRasterCaches,
  })  : layerCanvasStorage = layerCanvasStorage ?? LayerCanvasStorage(),
        layerRasterCaches = layerRasterCaches ?? {};

  ReferenceImage? get currentRefImage =>
      currentRefImageIndex >= 0 && currentRefImageIndex < referenceImages.length
          ? referenceImages[currentRefImageIndex]
          : null;

  EnhancedDrawingState copyWith({
    double? scale,
    double? rotation,
    double? offsetX,
    double? offsetY,
    bool? isErasing,
    List<ReferenceImage>? referenceImages,
    int? currentRefImageIndex,
    bool? isShowingReferenceImage,
    bool? isTransforming,
    bool? isRefImageDrawMode,
    LayerCanvasStorage? layerCanvasStorage,
    Map<String, LayerRasterCache>? layerRasterCaches,
  }) {
    return EnhancedDrawingState(
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      isErasing: isErasing ?? this.isErasing,
      referenceImages: referenceImages ?? this.referenceImages,
      currentRefImageIndex: currentRefImageIndex ?? this.currentRefImageIndex,
      isShowingReferenceImage:
          isShowingReferenceImage ?? this.isShowingReferenceImage,
      isTransforming: isTransforming ?? this.isTransforming,
      isRefImageDrawMode: isRefImageDrawMode ?? this.isRefImageDrawMode,
      layerCanvasStorage: layerCanvasStorage ?? this.layerCanvasStorage,
      layerRasterCaches: layerRasterCaches ?? this.layerRasterCaches,
    );
  }

  /// Get all strokes from a specific layer
  List<LayerStroke> getLayerStrokes(String layerId) {
    return layerCanvasStorage.getLayerCanvas(layerId).strokes;
  }
  
  /// Get cached image for a layer
  ui.Image? getCachedLayerImage(String layerId) {
    return layerRasterCaches[layerId]?.cachedImage;
  }
}

class EnhancedDrawingNotifier extends StateNotifier<EnhancedDrawingState> {
  EnhancedDrawingNotifier() : super(EnhancedDrawingState());

  static const uuid = Uuid();

  double _lastScale = 1.0;
  double _lastRotation = 0.0;
  bool _isDrawing = false;
  String? _currentStrokeId;
  
  // State tracking for undo/redo
  LayerCanvasStorage? _strokeStartState;
  String? _strokeLayerId;

  // Stroke stabilizer for smooth curves (replaces old stabilizer buffer)
  StrokeStabilizer? _strokeStabilizer;

  // Drag tracking
  Offset _dragStartPosition = Offset.zero;
  final double _dragStartScale = 1.0;

  // Undo/Redo history - simple list-based approach
  final List<LayerCanvasStorage> _undoStack = [];
  final List<LayerCanvasStorage> _redoStack = [];

  // For color tracking
  dynamic colorPickerRef;
  dynamic brushRef;

  /// Set references to access providers
  void setRefs({dynamic colorRef, dynamic brush}) {
    colorPickerRef = colorRef;
    brushRef = brush;
  }

  bool canUndo() => _undoStack.isNotEmpty;
  bool canRedo() => _redoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isNotEmpty) {
      // Save current state to redo stack
      _redoStack.add(state.layerCanvasStorage);
      
      // Restore previous state
      final previousState = _undoStack.removeLast();
      state = state.copyWith(layerCanvasStorage: previousState);
      
      // Invalidate all layer caches since strokes changed
      _invalidateAllLayerCaches();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      // Save current state to undo stack
      _undoStack.add(state.layerCanvasStorage);
      
      // Restore next state
      final nextState = _redoStack.removeLast();
      state = state.copyWith(layerCanvasStorage: nextState);
      
      // Invalidate all layer caches since strokes changed
      _invalidateAllLayerCaches();
    }
  }
  
  /// Invalidate all layer raster caches
  void _invalidateAllLayerCaches() {
    final newCaches = <String, LayerRasterCache>{...state.layerRasterCaches};
    for (final cache in newCaches.values) {
      cache.dispose();
    }
    newCaches.clear();
    state = state.copyWith(layerRasterCaches: newCaches);
  }
  
  /// Build raster cache for a specific layer
  Future<void> _buildLayerRasterCache(String layerId, Size canvasSize) async {
    final strokes = state.layerCanvasStorage.getLayerCanvas(layerId).strokes;
    if (strokes.isEmpty) {
      // No strokes, clear cache
      state.layerRasterCaches[layerId]?.dispose();
      final newCaches = <String, LayerRasterCache>{...state.layerRasterCaches};
      newCaches.remove(layerId);
      state = state.copyWith(layerRasterCaches: newCaches);
      return;
    }

    // Record all strokes to a picture
    final recorder = ui.PictureRecorder();
    final pictureCanvas = Canvas(recorder, Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height));

    // Draw all strokes
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      _drawCacheStrokeToCanvas(pictureCanvas, stroke);
    }

    // Convert picture to image
    final picture = recorder.endRecording();
    final cachedImage = await picture.toImage(canvasSize.width.toInt(), canvasSize.height.toInt());

    // Update cache
    final newCaches = <String, LayerRasterCache>{...state.layerRasterCaches};
    final cache = newCaches[layerId] ?? LayerRasterCache(layerId: layerId);
    cache.updateCache(cachedImage);
    newCaches[layerId] = cache;
    state = state.copyWith(layerRasterCaches: newCaches);
  }
  
  /// Draw a stroke to canvas for caching (same as painter)
  void _drawCacheStrokeToCanvas(Canvas canvas, LayerStroke stroke) {
    if (stroke.points.isEmpty) return;

    if (stroke.isEraser) {
      // Eraser stroke - uses BlendMode.clear to remove pixels
      final eraserPaint = Paint()
        ..color = Colors.transparent
        ..strokeWidth = stroke.strokeWidth
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high
        ..blendMode = BlendMode.clear;
      
      _renderCacheStroke(canvas, stroke.points, eraserPaint);
    } else {
      // Normal stroke - blend with opacity and flow
      final finalAlpha = (stroke.opacity * stroke.flow).clamp(0.0, 1.0);
      final brushPaint = Paint()
        ..color = stroke.color.withValues(alpha: stroke.color.alpha * finalAlpha)
        ..strokeWidth = stroke.strokeWidth
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;
      
      _renderCacheStroke(canvas, stroke.points, brushPaint);
    }
  }

  void _renderCacheStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      canvas.drawCircle(points[0], paint.strokeWidth / 2, paint);
      return;
    }

    final path = _buildCachePath(points);

    // Set stroke properties
    paint
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  Path _buildCachePath(List<Offset> points) {
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

  void setBrush() {
    state = state.copyWith(isErasing: false);
  }

  void setEraser() {
    state = state.copyWith(isErasing: true);
  }

  /// Start drawing on a specific layer
  void startDrawing(String layerId, Offset point, int pointerCount) {
    if (pointerCount > 1) {
      _isDrawing = false;
      _currentStrokeId = null;
      return;
    }

    if (pointerCount == 1) {
      _isDrawing = true;
      _currentStrokeId = uuid.v4();
      
      // Save state and layer for undo when stroke starts
      _strokeStartState = state.layerCanvasStorage;
      _strokeLayerId = layerId;

      // Create stroke for both brush and eraser modes
      double strokeWidth = 2.0;
      double opacity = 1.0;
      double flow = 1.0;
      double stabilizer = 0.0;
      Color strokeColor = Colors.black;
      
      if (brushRef != null) {
        try {
          final currentBrush = brushRef.read(brushProvider);
          strokeWidth = currentBrush.defaultSize;
          stabilizer = currentBrush.stabilizer;
          if (!state.isErasing) {
            opacity = currentBrush.defaultOpacity;
            flow = currentBrush.flow;
          }
          
          if (colorPickerRef != null) {
            strokeColor = colorPickerRef.read(colorPickerProvider).selectedColor;
          }
        } catch (e) {
          // Silently ignore if brush access fails
          strokeColor = Colors.black;
        }
      }

      // Initialize stroke stabilizer with current brush settings and canvas scale
      _strokeStabilizer = StrokeStabilizer(
        strength: stabilizer,
        canvasScale: state.scale,
      );
      _strokeStabilizer!.start(point);

      final newStroke = LayerStroke(
        id: _currentStrokeId!,
        points: [point],
        isEraser: state.isErasing,
        color: strokeColor,
        strokeWidth: strokeWidth,
        opacity: opacity,
        flow: flow,
      );

      var newStorage = state.layerCanvasStorage;
      newStorage = newStorage.addStrokeToLayer(layerId, newStroke);
      state = state.copyWith(layerCanvasStorage: newStorage);

      // Track color when user starts drawing (not for eraser)
      if (!state.isErasing && colorPickerRef != null) {
        try {
          final colorPickerNotifier =
              colorPickerRef.read(colorPickerProvider.notifier);
          final selectedColor =
              colorPickerRef.read(colorPickerProvider).selectedColor;
          colorPickerNotifier.trackColorUsedOnCanvas(selectedColor);
        } catch (e) {
          // Silently ignore if color tracking fails
        }
      }
    }
  }

  /// Continue drawing on a specific layer
  void draw(String layerId, Offset point, int pointerCount) {
    if (pointerCount == 1 && _isDrawing && _currentStrokeId != null) {
      var newStorage = state.layerCanvasStorage;
      
      // Get stroke width from brush
      double strokeWidth = 2.0;
      if (brushRef != null) {
        try {
          final currentBrush = brushRef.read(brushProvider);
          strokeWidth = currentBrush.defaultSize;
        } catch (e) {
          // Silently ignore
        }
      }
      
      // Pass raw point through stabilizer
      Offset? stabilizedPoint;
      if (_strokeStabilizer != null) {
        stabilizedPoint = _strokeStabilizer!.add(point);
      } else {
        stabilizedPoint = point;
      }
      
      // If stabilizer returns null, skip this frame (still within rope radius)
      if (stabilizedPoint == null) {
        return;
      }
      
      // Get current stroke points
      final lastStroke = state.layerCanvasStorage
              .getLayerCanvas(layerId)
              .getLastStroke();
      List<Offset> newPoints = [...(lastStroke?.points ?? [])];
      
      if (newPoints.isEmpty) {
        newPoints.add(stabilizedPoint);
      } else {
        final lastPoint = newPoints.last;
        final distance = (stabilizedPoint - lastPoint).distance;
        
        // Interpolation threshold based on stroke width
        final interpolationThreshold = max(1.0, strokeWidth * 0.25);
        
        if (distance > interpolationThreshold) {
          // Insert interpolated points using Catmull-Rom interpolation
          final interpolatedPoints = _catmullRomInterpolate(lastPoint, stabilizedPoint, strokeWidth);
          newPoints.addAll(interpolatedPoints);
        } else if (distance > 0) {
          // Add point if it has moved at all
          newPoints.add(stabilizedPoint);
        }
      }
      
      newStorage = newStorage.updateStrokeOnLayer(
        layerId,
        _currentStrokeId!,
        newPoints,
      );
      
      state = state.copyWith(layerCanvasStorage: newStorage);
    } else if (pointerCount > 1) {
      _isDrawing = false;
      _currentStrokeId = null;
      _strokeStabilizer = null;
    }
  }

  /// Catmull-Rom interpolation for smooth curves between sparse points
  List<Offset> _catmullRomInterpolate(Offset p0, Offset p3, double strokeWidth) {
    // For 2 points, we use simplified interpolation
    final interpolatedPoints = <Offset>[];
    final steps = max(2, (p3 - p0).distance / max(1.0, strokeWidth * 0.25)).ceil();
    
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final point = _catmullRomPoint(p0, p0, p3, p3, t);
      interpolatedPoints.add(point);
    }
    
    interpolatedPoints.add(p3);
    return interpolatedPoints;
  }

  /// Calculate a single point on a Catmull-Rom curve
  Offset _catmullRomPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    
    final a0 = -0.5 * t3 + t2 - 0.5 * t;
    final a1 = 1.5 * t3 - 2.5 * t2 + 1.0;
    final a2 = -1.5 * t3 + 2.0 * t2 + 0.5 * t;
    final a3 = 0.5 * t3 - 0.5 * t2;
    
    return Offset(
      a0 * p0.dx + a1 * p1.dx + a2 * p2.dx + a3 * p3.dx,
      a0 * p0.dy + a1 * p1.dy + a2 * p2.dy + a3 * p3.dy,
    );
  }

  void stopDrawing() {
    // Only flush remaining stabilizer points if stabilizer is actually active
    if (_isDrawing && _currentStrokeId != null && _strokeLayerId != null && _strokeStabilizer != null) {
      var newStorage = state.layerCanvasStorage;
      final lastStroke = newStorage.getLayerCanvas(_strokeLayerId!).getLastStroke();
      
      if (lastStroke != null) {
        // Only use finish points if stabilizer was actually active (strength > 0)
        // Otherwise skip finish to prevent unwanted connections between strokes
        if (_strokeStabilizer!.strength > 0.0) {
          final finishPoints = _strokeStabilizer!.finish();
          
          if (finishPoints.isNotEmpty) {
            List<Offset> newPoints = [...lastStroke.points];
            
            // Add finish points through gap interpolation
            for (final finishPoint in finishPoints) {
              if (newPoints.isNotEmpty) {
                final lastPoint = newPoints.last;
                final distance = (finishPoint - lastPoint).distance;
                
                // Get stroke width for interpolation threshold
                double strokeWidth = lastStroke.strokeWidth;
                final interpolationThreshold = max(1.0, strokeWidth * 0.25);
                
                if (distance > interpolationThreshold) {
                  // Insert interpolated points
                  final interpolatedPoints = _catmullRomInterpolate(lastPoint, finishPoint, strokeWidth);
                  newPoints.addAll(interpolatedPoints);
                } else if (distance > 0) {
                  newPoints.add(finishPoint);
                }
              } else {
                newPoints.add(finishPoint);
              }
            }
            
            newStorage = newStorage.updateStrokeOnLayer(
              _strokeLayerId!,
              _currentStrokeId!,
              newPoints,
            );
            state = state.copyWith(layerCanvasStorage: newStorage);
          }
        }
      }
    }
    
    if (_strokeStartState != null && _strokeLayerId != null && _isDrawing) {
      // Record the change in undo history
      _undoStack.add(_strokeStartState!);
      
      // Clear redo stack when a new action is performed
      _redoStack.clear();
      
      // Rebuild the layer's raster cache now that the stroke is complete
      _buildLayerRasterCache(_strokeLayerId!, const Size(1080, 2400));
    }
    
    _isDrawing = false;
    _currentStrokeId = null;
    _strokeStartState = null;
    _strokeLayerId = null;
    _strokeStabilizer = null;
  }

  /// Clear all strokes from a layer
  void clearLayer(String layerId) {
    var newStorage = state.layerCanvasStorage;
    newStorage = newStorage.clearLayerCanvas(layerId);
    state = state.copyWith(layerCanvasStorage: newStorage);
  }

  /// Delete a layer's canvas (called when layer is deleted)
  void deleteLayerCanvas(String layerId) {
    var newStorage = state.layerCanvasStorage;
    newStorage = newStorage.deleteLayerCanvas(layerId);
    state = state.copyWith(layerCanvasStorage: newStorage);
  }

  void onScaleStart(int pointerCount) {
    if (pointerCount > 1) {
      _isDrawing = false;
      _currentStrokeId = null;
      _lastScale = state.scale;
      _lastRotation = state.rotation;
    }
  }

  void onScaleUpdate(double scale, double rotation, int pointerCount) {
    if (pointerCount > 1) {
      _isDrawing = false;
      state = state.copyWith(
        scale: (_lastScale * scale).clamp(0.5, 5.0),
        rotation: _lastRotation + rotation,
      );
    }
  }

  void onDragStart(Offset position) {
    _dragStartPosition = position;
  }

  void updateMoveOffset(double dx, double dy) {
    state = state.copyWith(
      offsetX: state.offsetX + dx,
      offsetY: state.offsetY + dy,
    );
  }

  void startTransforming() {
    state = state.copyWith(isTransforming: true);
  }

  void stopTransforming() {
    state = state.copyWith(isTransforming: false);
  }

  void addReferenceImage(ReferenceImage image) {
    state = state.copyWith(
      referenceImages: [...state.referenceImages, image],
      currentRefImageIndex: state.referenceImages.length,
      isShowingReferenceImage: true,
    );
  }

  void updateReferenceImage(int index, ReferenceImage updatedImage) {
    final images = [...state.referenceImages];
    images[index] = updatedImage;
    state = state.copyWith(referenceImages: images);
  }

  void removeReferenceImage(int index) {
    final images = [...state.referenceImages];
    images.removeAt(index);
    int newIndex = state.currentRefImageIndex;
    if (newIndex >= images.length) {
      newIndex = images.length - 1;
    }
    state = state.copyWith(
      referenceImages: images,
      currentRefImageIndex: newIndex,
      isShowingReferenceImage: images.isNotEmpty,
    );
  }

  void setRefImageVisibility(bool isVisible) {
    state = state.copyWith(isShowingReferenceImage: isVisible);
  }

  void setRefImageDrawMode(bool isDrawMode) {
    state = state.copyWith(isRefImageDrawMode: isDrawMode);
  }

  void resetZoom() {
    state = state.copyWith(scale: 1.0);
  }

  void resetRotation() {
    state = state.copyWith(rotation: 0.0);
  }

  void resetScale() {
    state = state.copyWith(scale: 1.0);
  }

  void updateZoom(double delta) {
    final scaleChange = delta / 500;
    final newScale = (state.scale - scaleChange).clamp(0.5, 5.0);
    state = state.copyWith(scale: newScale);
  }

  void updateRotation(double delta) {
    final rotationChange = delta / 200;
    final newRotation = state.rotation + rotationChange;
    state = state.copyWith(rotation: newRotation);
  }

  void updateScale(double delta) {
    final scaleChange = delta / 500;
    final newScale = (state.scale - scaleChange).clamp(0.5, 5.0);
    state = state.copyWith(scale: newScale);
  }

  void resetZoomRotation() {
    state = state.copyWith(scale: 1.0, rotation: 0.0);
  }

  void resetAll() {
    state = state.copyWith(
      scale: 1.0,
      rotation: 0.0,
      offsetX: 0.0,
      offsetY: 0.0,
      isTransforming: false,
    );
  }

  void resetOffsetOnly() {
    state = state.copyWith(offsetX: 0.0, offsetY: 0.0, isTransforming: false);
  }

  // Reference Image Methods
  void hideReferenceImage() {
    state = state.copyWith(isShowingReferenceImage: false);
  }

  void showReferenceImage() {
    state = state.copyWith(isShowingReferenceImage: true);
  }

  void toggleRefImageDrawMode() {
    state = state.copyWith(isRefImageDrawMode: !state.isRefImageDrawMode);
  }

  void onRefImageScaleStart() {
    _lastScale = state.currentRefImage?.scale ?? 1.0;
  }

  void updateRefImageOffset(double dx, double dy) {
    final refImage = state.currentRefImage;
    if (refImage != null) {
      updateReferenceImage(
          state.currentRefImageIndex,
          refImage.copyWith(
            offsetX: refImage.offsetX + dx,
            offsetY: refImage.offsetY + dy,
          ));
    }
  }

  void onRefImageScaleUpdate(double scale, double rotation, int pointerCount) {
    final refImage = state.currentRefImage;
    if (refImage != null) {
      updateReferenceImage(
          state.currentRefImageIndex,
          refImage.copyWith(
            scale: (_lastScale * scale).clamp(0.1, 10.0),
            rotation: refImage.rotation + rotation,
          ));
    }
  }

  void previousRefImage() {
    if (state.referenceImages.isEmpty) return;
    int newIndex = state.currentRefImageIndex - 1;
    if (newIndex < 0) {
      newIndex = state.referenceImages.length - 1;
    }
    state = state.copyWith(currentRefImageIndex: newIndex);
  }

  void nextRefImage() {
    if (state.referenceImages.isEmpty) return;
    int newIndex = state.currentRefImageIndex + 1;
    if (newIndex >= state.referenceImages.length) {
      newIndex = 0;
    }
    state = state.copyWith(currentRefImageIndex: newIndex);
  }

  void toggleRefImageFlip() {
    final refImage = state.currentRefImage;
    if (refImage != null) {
      updateReferenceImage(
          state.currentRefImageIndex,
          refImage.copyWith(
            isFlipped: !refImage.isFlipped,
          ));
    }
  }

  void autoFitRefImage() {
    final refImage = state.currentRefImage;
    if (refImage != null) {
      updateReferenceImage(
          state.currentRefImageIndex,
          refImage.copyWith(
            scale: 1.0,
            offsetX: 0.0,
            offsetY: 0.0,
            rotation: 0.0,
          ));
    }
  }

  void resetRefImage() {
    final refImage = state.currentRefImage;
    if (refImage != null) {
      updateReferenceImage(
          state.currentRefImageIndex,
          refImage.copyWith(
            scale: 1.0,
            rotation: 0.0,
            offsetX: 0.0,
            offsetY: 0.0,
            isFlipped: false,
          ));
    }
  }

  void removeCurrentRefImage() {
    if (state.currentRefImageIndex >= 0 &&
        state.currentRefImageIndex < state.referenceImages.length) {
      removeReferenceImage(state.currentRefImageIndex);
    }
  }

  void setRefImageScale(double scale) {
    final refImage = state.currentRefImage;
    if (refImage != null) {
      updateReferenceImage(
          state.currentRefImageIndex,
          refImage.copyWith(
            scale: scale.clamp(0.1, 10.0),
          ));
    }
  }

  void setRefImageRotation(double rotation) {
    final refImage = state.currentRefImage;
    if (refImage != null) {
      updateReferenceImage(
          state.currentRefImageIndex,
          refImage.copyWith(
            rotation: rotation,
          ));
    }
  }

  void updateRefImageOpacity(double opacity) {
    final refImage = state.currentRefImage;
    if (refImage != null) {
      updateReferenceImage(
          state.currentRefImageIndex,
          refImage.copyWith(
            opacity: opacity.clamp(0.0, 1.0),
          ));
    }
  }

  void updateRefImageSaturation(double saturation) {
    final refImage = state.currentRefImage;
    if (refImage != null) {
      updateReferenceImage(
          state.currentRefImageIndex,
          refImage.copyWith(
            saturation: saturation.clamp(0.0, 2.0),
          ));
    }
  }
}

final enhancedDrawingNotifierProvider =
    StateNotifierProvider<EnhancedDrawingNotifier, EnhancedDrawingState>((ref) {
  final notifier = EnhancedDrawingNotifier();
  // Store ref for later use to access brush and color data
  notifier.setRefs(colorRef: ref, brush: ref);
  return notifier;
});
