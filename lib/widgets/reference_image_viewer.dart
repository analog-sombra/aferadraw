import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' as v3;
import '../providers/drawing_provider.dart';

class ReferenceImageViewer extends ConsumerStatefulWidget {
  const ReferenceImageViewer({super.key});

  @override
  ConsumerState<ReferenceImageViewer> createState() =>
      _ReferenceImageViewerState();
}

class _ReferenceImageViewerState extends ConsumerState<ReferenceImageViewer> {
  Offset? _dragStartPosition;
  final int _swipeThreshold = 50;
  bool _showControls = false;

  @override
  Widget build(BuildContext context) {
    final drawingProvider = ref.watch(drawingNotifierProvider);
    final notifier = ref.read(drawingNotifierProvider.notifier);
    final currentImage = drawingProvider.currentRefImage;
    final isDrawMode = drawingProvider.isRefImageDrawMode;

    if (currentImage == null) {
      return const SizedBox.shrink();
    }

    // Draw Mode: On canvas for tracing (non-interactive overlay)
    if (isDrawMode) {
      return Stack(
        children: [
          // Reference image - NON-INTERACTIVE overlay
          // Let canvas gestures pass through
          Positioned.fill(
            child: IgnorePointer(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  // Apply canvas transformations first
                  ..translateByVector3(v3.Vector3(drawingProvider.offsetX, drawingProvider.offsetY, 0))
                  ..scaleByVector3(v3.Vector3(drawingProvider.scale, drawingProvider.scale, 1))
                  ..rotateZ(drawingProvider.rotation)
                  // Apply reference image transformations
                  ..translateByVector3(v3.Vector3(currentImage.offsetX, currentImage.offsetY, 0))
                  ..scaleByVector3(v3.Vector3(
                      currentImage.scale *
                          (currentImage.isFlipped ? -1 : 1),
                      currentImage.scale,
                      1))
                  ..rotateZ(currentImage.rotation),
                child: Opacity(
                  opacity: currentImage.opacity,
                  child: ColorFiltered(
                    colorFilter: ui.ColorFilter.matrix(
                      _getSaturationMatrix(currentImage.saturation),
                    ),
                    child: Image.file(
                      File(currentImage.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Close button - only interactive element
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.close),
                color: Colors.white,
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  notifier.toggleRefImageDrawMode();
                },
              ),
            ),
          ),
        ],
      );
    }

    // Normal Mode: Full-screen overlay with all controls
    return Positioned.fill(
      child: Container(
        color: Colors.black12,
        child: Stack(
          children: [
            GestureDetector(
              onScaleStart: (details) {
                _dragStartPosition = details.focalPoint;
                if (details.pointerCount > 1) {
                  notifier.onRefImageScaleStart(details.pointerCount);
                }
              },
              onScaleUpdate: (details) {
                if (details.pointerCount == 1) {
                  if (_dragStartPosition != null) {
                    final delta = details.focalPoint - _dragStartPosition!;
                    notifier.updateRefImageOffset(delta.dx, delta.dy);
                    _dragStartPosition = details.focalPoint;
                  }
                } else if (details.pointerCount > 1) {
                  notifier.onRefImageScaleUpdate(
                    details.scale,
                    details.rotation,
                    details.pointerCount,
                  );
                }
              },
              onScaleEnd: (details) {
                _dragStartPosition = null;
              },
              onHorizontalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dx > _swipeThreshold) {
                  notifier.previousRefImage();
                } else if (details.velocity.pixelsPerSecond.dx < -_swipeThreshold) {
                  notifier.nextRefImage();
                }
              },
              child: SizedBox.expand(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translateByVector3(v3.Vector3(currentImage.offsetX, currentImage.offsetY, 0))
                        ..scaleByVector3(v3.Vector3(
                            currentImage.scale *
                                (currentImage.isFlipped ? -1 : 1),
                            currentImage.scale,
                            1))
                        ..rotateZ(currentImage.rotation),
                      child: Opacity(
                        opacity: currentImage.opacity,
                        child: ColorFiltered(
                          colorFilter: ui.ColorFilter.matrix(
                            _getSaturationMatrix(currentImage.saturation),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(currentImage.imagePath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[600]!, width: 1),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.flip_to_back),
                      color: currentImage.isFlipped ? Colors.orange : Colors.white,
                      tooltip: 'Flip horizontal',
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        notifier.toggleRefImageFlip();
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.fit_screen),
                      color: Colors.white,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Auto-fit to screen',
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        notifier.autoFitRefImage();
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      color: Colors.white,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Reset transform',
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        notifier.resetRefImage();
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.draw),
                      color: Colors.greenAccent,
                      tooltip: 'Enter draw mode',
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        notifier.toggleRefImageDrawMode();
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      color: _showControls ? Colors.orange : Colors.white,
                      tooltip: 'Show/Hide controls',
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _showControls = !_showControls;
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      tooltip: 'Remove this reference image',
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        notifier.removeCurrentRefImage();
                        if (drawingProvider.referenceImages.length <= 1) {
                          notifier.hideReferenceImage();
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                      tooltip: 'Close reference image',
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        notifier.hideReferenceImage();
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_showControls)
              Positioned(
                top: 64,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Controls:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Swipe left/right: Switch images',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      const Text(
                        '• One finger tap + drag: Move image',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      const Text(
                        '• Two fingers drag: Scale & rotate',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 8,
              top: 70,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 16),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 100,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: currentImage.scale,
                          onChanged: (value) {
                            notifier.setRefImageScale(value);
                          },
                          min: 0.1,
                          max: 3.0,
                          activeColor: Colors.blue,
                          inactiveColor: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${(currentImage.scale * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: Colors.grey[600],
                      thickness: 1,
                      height: 8,
                    ),
                    const SizedBox(height: 12),
                    Icon(Icons.rotate_right, color: Colors.white, size: 16),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 100,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: currentImage.rotation,
                          onChanged: (value) {
                            notifier.setRefImageRotation(value);
                          },
                          min: -3.14159,
                          max: 3.14159,
                          activeColor: Colors.orange,
                          inactiveColor: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${((currentImage.rotation * 180) / 3.14159).toStringAsFixed(0)}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (drawingProvider.referenceImages.length > 1)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    drawingProvider.referenceImages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == drawingProvider.currentRefImageIndex
                            ? Colors.white
                            : Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.opacity, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 1,
                      child: Slider(
                        value: currentImage.opacity,
                        onChanged: (value) {
                          notifier.updateRefImageOpacity(value);
                        },
                        min: 0.0,
                        max: 1.0,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${(currentImage.opacity * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    VerticalDivider(
                      color: Colors.grey[600],
                      thickness: 1,
                      width: 8,
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.palette, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 1,
                      child: Slider(
                        value: currentImage.saturation,
                        onChanged: (value) {
                          notifier.updateRefImageSaturation(value);
                        },
                        min: 0.0,
                        max: 2.0,
                        activeColor: Colors.orange,
                        inactiveColor: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${(currentImage.saturation * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _getSaturationMatrix(double saturation) {
    final s = saturation;
    final sr = (1 - s) * 0.299;
    final sg = (1 - s) * 0.587;
    final sb = (1 - s) * 0.114;

    return [
      sr + s, sg, sb, 0, 0,
      sr, sg + s, sb, 0, 0,
      sr, sg, sb + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}

class GridPainterOverlay extends CustomPainter {
  final int divisions;

  GridPainterOverlay(this.divisions);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    final cellWidth = size.width / divisions;
    final cellHeight = size.height / divisions;

    for (int i = 1; i < divisions; i++) {
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        paint,
      );
    }

    for (int i = 1; i < divisions; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainterOverlay oldDelegate) =>
      oldDelegate.divisions != divisions;
}
