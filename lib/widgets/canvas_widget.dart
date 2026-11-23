import 'package:material_ui/material_ui.dart';
import 'package:vector_math/vector_math_64.dart' as v3;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/enhanced_drawing_notifier.dart';
import '../features/layers/providers/layer_provider.dart';
import '../features/layers/models/layer_canvas_model.dart';
import '../painters/grid_painter.dart';
import '../painters/enhanced_drawing_painter.dart';
import 'reference_image_viewer.dart';

class CanvasWidget extends ConsumerStatefulWidget {
  const CanvasWidget({super.key});

  @override
  ConsumerState<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends ConsumerState<CanvasWidget> {
  @override
  void initState() {
    super.initState();
    // Set up callback for layer deletion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final layerNotifier = ref.read(layerStackProvider.notifier);
      final drawingNotifier =
          ref.read(enhancedDrawingNotifierProvider.notifier);

      layerNotifier.onLayerDeleted = (layerId) {
        drawingNotifier.deleteLayerCanvas(layerId);
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final drawingProvider = ref.watch(enhancedDrawingNotifierProvider);
    final notifier = ref.read(enhancedDrawingNotifierProvider.notifier);
    final layerStack = ref.watch(layerStackProvider);
    final canvasKey = GlobalKey();

    return Expanded(
      child: Stack(
        children: [
          _CanvasGestureHandler(
            canvasKey: canvasKey,
            isShowingRef: drawingProvider.isShowingReferenceImage &&
                !drawingProvider.isRefImageDrawMode,
            notifier: notifier,
            drawingProvider: drawingProvider,
            layerStack: layerStack,
          ),
          if (drawingProvider.currentRefImage != null &&
              drawingProvider.isShowingReferenceImage)
            const ReferenceImageViewer(),
        ],
      ),
    );
  }
}

class _CanvasGestureHandler extends StatefulWidget {
  final GlobalKey canvasKey;
  final bool isShowingRef;
  final dynamic notifier;
  final dynamic drawingProvider;
  final dynamic layerStack;

  const _CanvasGestureHandler({
    required this.canvasKey,
    required this.isShowingRef,
    required this.notifier,
    required this.drawingProvider,
    required this.layerStack,
  });

  @override
  State<_CanvasGestureHandler> createState() => _CanvasGestureHandlerState();
}

class _CanvasGestureHandlerState extends State<_CanvasGestureHandler> {
  Offset? dragStartPosition;

  bool _canDraw() {
    // Check if active layer is locked or hidden
    final activeLayer = widget.layerStack.activeLayer;
    if (activeLayer == null) return false;
    if (activeLayer.isLocked) return false;
    if (!activeLayer.isVisible) return false;
    if (activeLayer.type == 'group') {
      return false; // Cannot draw on group layers
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: GridPainter(),
          size: Size.infinite,
        ),
        Container(
          color: Colors.transparent,
          padding: const EdgeInsets.all(20),
          child: GestureDetector(
            onLongPressStart: (details) {
              dragStartPosition = details.globalPosition;
              widget.notifier.startTransforming();
            },
            onLongPressMoveUpdate: (details) {
              if (dragStartPosition != null && !widget.isShowingRef) {
                final delta = details.globalPosition - dragStartPosition!;
                widget.notifier.updateMoveOffset(delta.dx, delta.dy);
                dragStartPosition = details.globalPosition;
              }
            },
            onLongPressEnd: (details) {
              dragStartPosition = null;
              widget.notifier.stopTransforming();
            },
            onScaleStart: (details) {
              if (!widget.isShowingRef && details.pointerCount == 1) {
                if (!_canDraw()) return;
                widget.notifier.onScaleStart(details.pointerCount);
                final renderBox = widget.canvasKey.currentContext
                    ?.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  final localPos = renderBox.globalToLocal(details.focalPoint);
                  widget.notifier.startDrawing(
                    widget.layerStack.activeLayer!.id,
                    localPos,
                    details.pointerCount,
                  );
                }
              } else if (details.pointerCount > 1) {
                widget.notifier.startTransforming();
                widget.notifier.onScaleStart(details.pointerCount);
              }
            },
            onScaleUpdate: (details) {
              if (!widget.isShowingRef) {
                if (details.pointerCount == 1) {
                  if (!_canDraw()) return;
                  final renderBox = widget.canvasKey.currentContext
                      ?.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final localPos =
                        renderBox.globalToLocal(details.focalPoint);
                    widget.notifier.draw(
                      widget.layerStack.activeLayer!.id,
                      localPos,
                      details.pointerCount,
                    );
                  }
                } else if (details.pointerCount > 1) {
                  widget.notifier.startTransforming();
                  widget.notifier.onScaleUpdate(
                      details.scale, details.rotation, details.pointerCount);
                }
              }
            },
            onScaleEnd: (details) {
              if (!widget.isShowingRef) {
                widget.notifier.stopDrawing();
                widget.notifier.stopTransforming();
              }
            },
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translateByVector3(v3.Vector3(widget.drawingProvider.offsetX,
                    widget.drawingProvider.offsetY, 0))
                ..scaleByVector3(v3.Vector3(widget.drawingProvider.scale,
                    widget.drawingProvider.scale, 1))
                ..rotateZ(widget.drawingProvider.rotation),
              child: ClipRect(
                child: Container(
                  key: widget.canvasKey,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: widget.drawingProvider.isTransforming
                          ? Colors.red
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: CustomPaint(
                    painter: EnhancedDrawingPainter(
                      layerStrokes: <String, List<LayerStroke>>{
                        for (final layer in widget.layerStack.layers)
                          layer.id: widget.drawingProvider.layerCanvasStorage
                              .getLayerCanvas(layer.id)
                              .strokes
                      },
                      layerOpacities: <String, double>{
                        for (final layer in widget.layerStack.layers)
                          layer.id: layer.opacity
                      },
                      layerVisibility: <String, bool>{
                        for (final layer in widget.layerStack.layers)
                          layer.id: layer.isVisible
                      },
                      layerBlendModes: <String, BlendMode>{
                        for (final layer in widget.layerStack.layers)
                          layer.id: layer.blendMode
                      },
                      layerOrder: <String>[
                        for (final layer in widget.layerStack.layers) layer.id
                      ],
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
