import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../widgets/canvas_widget.dart';
import '../../features/layers/widgets/layer_panel.dart';
import '../../features/layers/providers/layer_panel_provider.dart';
import '../../features/color_picker/widgets/color_picker_panel.dart';
import '../../features/color_picker/providers/color_picker_provider.dart';
import '../../features/brush/widgets/brush_panel.dart';
import '../../features/brush/providers/brush_provider.dart';
import '../../features/info_panel/providers/info_panel_provider.dart';
import '../../notifiers/enhanced_drawing_notifier.dart';
import '../../models/drawing_models.dart';

class DrawingScreen extends ConsumerWidget {
  const DrawingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLayerPanelOpen = ref.watch(layerPanelOpenProvider);
    final isColorPickerOpen = ref.watch(colorPickerOpenProvider);
    final isBrushPanelOpen = ref.watch(brushPanelOpenProvider);
    final isInfoPanelOpen = ref.watch(infoPanelOpenProvider);
    final drawingProvider = ref.watch(enhancedDrawingNotifierProvider);
    final drawingNotifier = ref.read(enhancedDrawingNotifierProvider.notifier);

    Future<void> pickReferenceImage() async {
      final picker = ImagePicker();
      try {
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          drawingNotifier.addReferenceImage(ReferenceImage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            imagePath: pickedFile.path,
          ));
        }
      } catch (e) {
        debugPrint('Error picking image: $e');
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main Drawing UI (without layer button in toolbar)
            Column(
              children: [
                const CanvasWidget(),
              ],
            ),

            // Color Picker Panel (Slides from right)
            ColorPickerPanelWidget(
              isOpen: isColorPickerOpen,
              onClose: () {
                ref.read(colorPickerOpenProvider.notifier).state = false;
              },
            ),

            // Layer Panel (Slides from right)
            LayerPanelWidget(
              isOpen: isLayerPanelOpen,
              onClose: () {
                ref.read(layerPanelOpenProvider.notifier).state = false;
              },
            ),

            // Brush Panel (Slides from right)
            BrushPanelWidget(
              isOpen: isBrushPanelOpen,
              onClose: () {
                ref.read(brushPanelOpenProvider.notifier).state = false;
              },
            ),

            // Action Box (Undo, Redo, Brush/Eraser, Ref Image, Info)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: (isLayerPanelOpen || isBrushPanelOpen || isColorPickerOpen) ? 328 : 8,
              bottom: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[700]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Undo Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: drawingNotifier.canUndo()
                            ? () {
                                drawingNotifier.undo();
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: drawingNotifier.canUndo()
                                ? Colors.blue
                                : Colors.grey[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.undo,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Redo Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: drawingNotifier.canRedo()
                            ? () {
                                drawingNotifier.redo();
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: drawingNotifier.canRedo()
                                ? Colors.cyan
                                : Colors.grey[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.redo,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Brush/Eraser Toggle
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (drawingProvider.isErasing) {
                            drawingNotifier.setBrush();
                          } else {
                            drawingNotifier.setEraser();
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: drawingProvider.isErasing
                                ? Colors.red
                                : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            drawingProvider.isErasing
                                ? Icons.cleaning_services
                                : Icons.brush,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Reference Image Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (drawingProvider.currentRefImage != null) {
                            if (drawingProvider.isShowingReferenceImage) {
                              drawingNotifier.hideReferenceImage();
                            } else {
                              drawingNotifier.showReferenceImage();
                            }
                          } else {
                            pickReferenceImage();
                          }
                        },
                        onLongPress: pickReferenceImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: drawingProvider.isShowingReferenceImage
                                ? Colors.purple
                                : Colors.grey[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: drawingProvider.currentRefImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(drawingProvider
                                        .currentRefImage!.imagePath),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Info Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ref.read(infoPanelOpenProvider.notifier).state =
                              !isInfoPanelOpen;
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isInfoPanelOpen
                                ? Colors.indigo
                                : Colors.grey[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.info,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info Panel (Top right, shows zoom, rotate, position)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: isInfoPanelOpen ? 8 : -320,
              top: 16,
              width: 300,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[700]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Canvas Info',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ref.read(infoPanelOpenProvider.notifier).state =
                                false;
                          },
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Zoom Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.zoom_in,
                                color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${(drawingProvider.scale * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => drawingNotifier.resetZoom(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Rotation Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.rotate_right,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${(drawingProvider.rotation * 180 / 3.14159).toStringAsFixed(0)}°',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => drawingNotifier.resetRotation(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Position Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pan_tool,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'X:${drawingProvider.offsetX.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Y:${drawingProvider.offsetY.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => drawingNotifier.resetAll(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Control Panel Box (Layer, Color, Brush buttons grouped)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: (isLayerPanelOpen || isBrushPanelOpen) ? 328 : 8,
              top: MediaQuery.of(context).size.height / 2 - 50,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[700]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Layer Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (isLayerPanelOpen) {
                            ref.read(layerPanelOpenProvider.notifier).state =
                                false;
                          } else {
                            ref.read(layerPanelOpenProvider.notifier).state =
                                true;
                            ref.read(colorPickerOpenProvider.notifier).state =
                                false;
                            ref.read(brushPanelOpenProvider.notifier).state =
                                false;
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isLayerPanelOpen
                                ? Icons.layers_clear
                                : Icons.layers,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Color Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (isColorPickerOpen) {
                            ref.read(colorPickerOpenProvider.notifier).state =
                                false;
                          } else {
                            ref.read(colorPickerOpenProvider.notifier).state =
                                true;
                            ref.read(layerPanelOpenProvider.notifier).state =
                                false;
                            ref.read(brushPanelOpenProvider.notifier).state =
                                false;
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.palette,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Brush Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (isBrushPanelOpen) {
                            ref.read(brushPanelOpenProvider.notifier).state =
                                false;
                          } else {
                            ref.read(brushPanelOpenProvider.notifier).state =
                                true;
                            ref.read(layerPanelOpenProvider.notifier).state =
                                false;
                            ref.read(colorPickerOpenProvider.notifier).state =
                                false;
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.brush,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
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
}
