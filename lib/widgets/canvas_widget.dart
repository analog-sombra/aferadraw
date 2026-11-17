import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/drawing_provider.dart';
import '../painters/grid_painter.dart';
import '../painters/drawing_painter.dart';
import 'reference_image_viewer.dart';

class CanvasWidget extends ConsumerWidget {
  const CanvasWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingProvider = ref.watch(drawingNotifierProvider);
    final notifier = ref.read(drawingNotifierProvider.notifier);
    final canvasKey = GlobalKey();

    return Expanded(
      child: Stack(
        children: [
          _CanvasGestureHandler(
            canvasKey: canvasKey,
            isShowingRef: drawingProvider.isShowingReferenceImage && !drawingProvider.isRefImageDrawMode,
            notifier: notifier,
            drawingProvider: drawingProvider,
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

  const _CanvasGestureHandler({
    required this.canvasKey,
    required this.isShowingRef,
    required this.notifier,
    required this.drawingProvider,
  });

  @override
  State<_CanvasGestureHandler> createState() => _CanvasGestureHandlerState();
}

class _CanvasGestureHandlerState extends State<_CanvasGestureHandler> {
  Offset? dragStartPosition;

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
                widget.notifier.onScaleStart(details.pointerCount);
                final renderBox = widget.canvasKey.currentContext
                    ?.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  final localPos =
                      renderBox.globalToLocal(details.focalPoint);
                  widget.notifier.startDrawing(localPos, details.pointerCount);
                }
              } else if (details.pointerCount > 1) {
                widget.notifier.startTransforming();
                widget.notifier.onScaleStart(details.pointerCount);
              }
            },
            onScaleUpdate: (details) {
              if (!widget.isShowingRef) {
                if (details.pointerCount == 1) {
                  final renderBox = widget.canvasKey.currentContext
                      ?.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final localPos =
                        renderBox.globalToLocal(details.focalPoint);
                    widget.notifier.draw(localPos, details.pointerCount);
                  }
                } else if (details.pointerCount > 1) {
                  widget.notifier.startTransforming();
                  widget.notifier.onScaleUpdate(details.scale, details.rotation,
                      details.pointerCount);
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
                ..translate(widget.drawingProvider.offsetX, widget.drawingProvider.offsetY)
                ..scale(widget.drawingProvider.scale, widget.drawingProvider.scale)
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
                    painter: DrawingPainter(widget.drawingProvider.lines),
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
