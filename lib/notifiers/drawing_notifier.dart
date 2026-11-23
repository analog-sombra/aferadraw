import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drawing_models.dart';

class DrawingNotifier extends StateNotifier<DrawingState> {
  DrawingNotifier() : super(DrawingState(lines: [], isErasing: false));

  double _lastScale = 1.0;
  double _lastRotation = 0.0;
  bool _isDrawing = false;

  // Drag tracking
  Offset _dragStartPosition = Offset.zero;
  double _dragStartScale = 1.0;

  void setBrush() {
    state = state.copyWith(isErasing: false);
  }

  void setEraser() {
    state = state.copyWith(isErasing: true);
  }

  void clear() {
    state = state.copyWith(lines: []);
  }

  void startDrawing(Offset point, int pointerCount) {
    if (pointerCount > 1) {
      _isDrawing = false;
      _removeSinglePointLine();
      return;
    }

    if (pointerCount == 1) {
      _isDrawing = true;
      final newLine = DrawingLine(
        points: [point],
        isEraser: state.isErasing,
        color: state.isErasing ? Colors.transparent : Colors.black,
        strokeWidth: state.isErasing ? 20.0 : 2.0,
      );
      state = state.copyWith(
        lines: [...state.lines, newLine],
      );
    }
  }

  void draw(Offset point, int pointerCount) {
    if (pointerCount == 1 && _isDrawing && state.lines.isNotEmpty) {
      final updatedLines = [...state.lines];
      final lastLine = updatedLines.last;

      updatedLines[updatedLines.length - 1] = lastLine.copyWith(
        points: [...lastLine.points, point],
      );
      state = state.copyWith(lines: updatedLines);
    } else if (pointerCount > 1) {
      _isDrawing = false;
      _removeSinglePointLine();
    }
  }

  void stopDrawing() {
    _isDrawing = false;
    _removeSinglePointLine();
  }

  void _removeSinglePointLine() {
    if (state.lines.isNotEmpty) {
      final lastLine = state.lines.last;
      if (lastLine.points.length == 1) {
        state = state.copyWith(
          lines: state.lines.sublist(0, state.lines.length - 1),
        );
      }
    }
  }

  void onScaleStart(int pointerCount) {
    if (pointerCount > 1) {
      _isDrawing = false;
      _removeSinglePointLine();
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
    _dragStartScale = state.scale;
  }

  void onVerticalDragUpdate(Offset position) {
    final dragDelta = position.dy - _dragStartPosition.dy;
    final scaleChange = -dragDelta / 200;
    final newScale = (_dragStartScale + scaleChange).clamp(0.5, 5.0);
    state = state.copyWith(scale: newScale);
  }

  void onDragEnd() {
    _dragStartPosition = Offset.zero;
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

  void resetMove() {
    state = state.copyWith(offsetX: 0.0, offsetY: 0.0);
  }

  void startTransforming() {
    state = state.copyWith(isTransforming: true);
  }

  void stopTransforming() {
    state = state.copyWith(isTransforming: false);
  }

  void updateMoveOffset(double deltaX, double deltaY) {
    final newOffsetX = state.offsetX + deltaX;
    final newOffsetY = state.offsetY + deltaY;
    state = state.copyWith(
        offsetX: newOffsetX, offsetY: newOffsetY, isTransforming: true);
  }

  // Reference Image Methods
  void addReferenceImage(String imagePath) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newRefImage = ReferenceImage(
      id: newId,
      imagePath: imagePath,
    );
    final updatedImages = [...state.referenceImages, newRefImage];
    state = state.copyWith(
      referenceImages: updatedImages,
      currentRefImageIndex: updatedImages.length - 1,
    );
  }

  void removeCurrentRefImage() {
    if (state.currentRefImage == null) return;

    final updatedImages = state.referenceImages
        .where((img) => img.id != state.currentRefImage!.id)
        .toList();

    int newIndex = state.currentRefImageIndex;
    if (newIndex >= updatedImages.length) {
      newIndex = updatedImages.length - 1;
    }

    state = state.copyWith(
      referenceImages: updatedImages,
      currentRefImageIndex: newIndex >= 0 ? newIndex : 0,
      isShowingReferenceImage:
          updatedImages.isNotEmpty ? state.isShowingReferenceImage : false,
    );
  }

  void selectRefImage(int index) {
    if (index >= 0 && index < state.referenceImages.length) {
      state = state.copyWith(currentRefImageIndex: index);
    }
  }

  void nextRefImage() {
    if (state.referenceImages.isEmpty) return;
    final nextIndex =
        (state.currentRefImageIndex + 1) % state.referenceImages.length;
    selectRefImage(nextIndex);
  }

  void previousRefImage() {
    if (state.referenceImages.isEmpty) return;
    final prevIndex = state.currentRefImageIndex == 0
        ? state.referenceImages.length - 1
        : state.currentRefImageIndex - 1;
    selectRefImage(prevIndex);
  }

  void showReferenceImage() {
    if (state.referenceImages.isNotEmpty) {
      state = state.copyWith(isShowingReferenceImage: true);
    }
  }

  void hideReferenceImage() {
    state = state.copyWith(isShowingReferenceImage: false);
  }

  void toggleRefImageDrawMode() {
    state = state.copyWith(isRefImageDrawMode: !state.isRefImageDrawMode);
  }

  void updateRefImageZoom(double delta) {
    final currentImage = state.currentRefImage;
    if (currentImage == null) return;

    final scaleChange = delta / 500;
    final newScale = (currentImage.scale - scaleChange).clamp(0.5, 5.0);

    final updatedImages = state.referenceImages.map((img) {
      return img.id == currentImage.id ? img.copyWith(scale: newScale) : img;
    }).toList();

    state = state.copyWith(referenceImages: updatedImages);
  }

  void setRefImageScale(double scale) {
    final currentImage = state.currentRefImage;
    if (currentImage == null) return;

    final clampedScale = scale.clamp(0.1, 3.0);

    final updatedImages = state.referenceImages.map((img) {
      return img.id == currentImage.id
          ? img.copyWith(scale: clampedScale)
          : img;
    }).toList();

    state = state.copyWith(referenceImages: updatedImages);
  }

  void updateRefImageRotation(double delta) {
    final currentImage = state.currentRefImage;
    if (currentImage == null) return;

    final rotationChange = delta / 200;
    final newRotation = currentImage.rotation + rotationChange;

    final updatedImages = state.referenceImages.map((img) {
      return img.id == currentImage.id
          ? img.copyWith(rotation: newRotation)
          : img;
    }).toList();

    state = state.copyWith(referenceImages: updatedImages);
  }

  void setRefImageRotation(double rotation) {
    final currentImage = state.currentRefImage;
    if (currentImage == null) return;

    final updatedImages = state.referenceImages.map((img) {
      return img.id == currentImage.id ? img.copyWith(rotation: rotation) : img;
    }).toList();

    state = state.copyWith(referenceImages: updatedImages);
  }

  void updateRefImageOffset(double deltaX, double deltaY) {
    final currentImage = state.currentRefImage;
    if (currentImage == null) return;

    final newOffsetX = currentImage.offsetX + deltaX;
    final newOffsetY = currentImage.offsetY + deltaY;

    final updatedImages = state.referenceImages.map((img) {
      return img.id == currentImage.id
          ? img.copyWith(offsetX: newOffsetX, offsetY: newOffsetY)
          : img;
    }).toList();

    state = state.copyWith(referenceImages: updatedImages);
  }

  void onRefImageScaleStart(int pointerCount) {
    if (pointerCount > 1) {
      final currentImage = state.currentRefImage;
      if (currentImage != null) {
        _lastScale = currentImage.scale;
        _lastRotation = currentImage.rotation;
      }
    }
  }

  void onRefImageScaleUpdate(double scale, double rotation, int pointerCount) {
    if (pointerCount > 1) {
      final currentImage = state.currentRefImage;
      if (currentImage == null) return;

      final newScale = (_lastScale * scale).clamp(0.5, 5.0);
      final newRotation = _lastRotation + rotation;

      final updatedImages = state.referenceImages.map((img) {
        return img.id == currentImage.id
            ? img.copyWith(scale: newScale, rotation: newRotation)
            : img;
      }).toList();

      state = state.copyWith(referenceImages: updatedImages);
    }
  }

  void resetRefImage() {
    final currentImage = state.currentRefImage;
    if (currentImage == null) return;

    final updatedImages = state.referenceImages.map((img) {
      return img.id == currentImage.id
          ? img.copyWith(scale: 1.0, rotation: 0.0, offsetX: 0.0, offsetY: 0.0)
          : img;
    }).toList();

    state = state.copyWith(referenceImages: updatedImages);
  }

  void updateRefImageOpacity(double opacity) {
    final currentImage = state.currentRefImage;
    if (currentImage == null) return;

    final clampedOpacity = opacity.clamp(0.0, 1.0);
    final updatedImages = state.referenceImages.map((img) {
      return img.id == currentImage.id
          ? img.copyWith(opacity: clampedOpacity)
          : img;
    }).toList();

    state = state.copyWith(referenceImages: updatedImages);
  }

  void updateRefImageSaturation(double saturation) {
    final currentImage = state.currentRefImage;
    if (currentImage == null) return;

    final clampedSaturation = saturation.clamp(0.0, 2.0);
    final updatedImages = state.referenceImages.map((img) {
      return img.id == currentImage.id
          ? img.copyWith(saturation: clampedSaturation)
          : img;
    }).toList();

    state = state.copyWith(referenceImages: updatedImages);
  }

  void toggleRefImageFlip() {
    final currentImage = state.currentRefImage;
    if (currentImage == null) return;

    final updatedImages = state.referenceImages.map((img) {
      return img.id == currentImage.id
          ? img.copyWith(isFlipped: !currentImage.isFlipped)
          : img;
    }).toList();

    state = state.copyWith(referenceImages: updatedImages);
  }

  void toggleAspectRatioLock() {
    final currentImage = state.currentRefImage;
    if (currentImage == null) return;

    final updatedImages = state.referenceImages.map((img) {
      return img.id == currentImage.id
          ? img.copyWith(aspectRatioLocked: !currentImage.aspectRatioLocked)
          : img;
    }).toList();

    state = state.copyWith(referenceImages: updatedImages);
  }

  void toggleGridOverlay() {
    final currentImage = state.currentRefImage;
    if (currentImage == null) return;

    final updatedImages = state.referenceImages.map((img) {
      return img.id == currentImage.id
          ? img.copyWith(showGrid: !currentImage.showGrid)
          : img;
    }).toList();

    state = state.copyWith(referenceImages: updatedImages);
  }

  void autoFitRefImage() {
    final currentImage = state.currentRefImage;
    if (currentImage == null) return;

    final updatedImages = state.referenceImages.map((img) {
      return img.id == currentImage.id
          ? img.copyWith(scale: 0.8, offsetX: 0.0, offsetY: 0.0, rotation: 0.0)
          : img;
    }).toList();

    state = state.copyWith(referenceImages: updatedImages);
  }
}
