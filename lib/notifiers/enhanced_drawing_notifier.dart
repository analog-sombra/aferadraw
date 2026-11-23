import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/drawing_models.dart';
import '../features/layers/models/layer_canvas_model.dart';
import '../features/color_picker/providers/color_picker_provider.dart';

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
  }) : layerCanvasStorage = layerCanvasStorage ?? LayerCanvasStorage();

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
    );
  }

  /// Get all strokes from a specific layer
  List<LayerStroke> getLayerStrokes(String layerId) {
    return layerCanvasStorage.getLayerCanvas(layerId).strokes;
  }
}

class EnhancedDrawingNotifier extends StateNotifier<EnhancedDrawingState> {
  EnhancedDrawingNotifier() : super(EnhancedDrawingState());

  static const uuid = Uuid();

  double _lastScale = 1.0;
  double _lastRotation = 0.0;
  bool _isDrawing = false;
  String? _currentStrokeId;

  // Drag tracking
  Offset _dragStartPosition = Offset.zero;
  final double _dragStartScale = 1.0;

  // For color tracking
  dynamic colorPickerRef;

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

      final newStroke = LayerStroke(
        id: _currentStrokeId!,
        points: [point],
        isEraser: state.isErasing,
        color: state.isErasing ? Colors.transparent : Colors.black,
        strokeWidth: state.isErasing ? 20.0 : 2.0,
      );

      var newStorage = state.layerCanvasStorage;
      newStorage = newStorage.addStrokeToLayer(layerId, newStroke);
      state = state.copyWith(layerCanvasStorage: newStorage);

      // Track color when user starts drawing (not erasing)
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
      newStorage = newStorage.updateStrokeOnLayer(
        layerId,
        _currentStrokeId!,
        [
          ...state.layerCanvasStorage
                  .getLayerCanvas(layerId)
                  .getLastStroke()
                  ?.points ??
              [],
          point,
        ],
      );
      state = state.copyWith(layerCanvasStorage: newStorage);
    } else if (pointerCount > 1) {
      _isDrawing = false;
      _currentStrokeId = null;
    }
  }

  void stopDrawing() {
    _isDrawing = false;
    _currentStrokeId = null;
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
  // Store ref for later use to track colors
  notifier.colorPickerRef = ref;
  return notifier;
});
