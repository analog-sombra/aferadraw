import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/toolbar_widget.dart';
import '../../widgets/canvas_widget.dart';
import '../../widgets/controls_widget.dart';
import '../../features/layers/widgets/layer_panel.dart';
import '../../features/layers/providers/layer_panel_provider.dart';
import '../../features/color_picker/widgets/color_picker_panel.dart';
import '../../features/color_picker/providers/color_picker_provider.dart';

class DrawingScreen extends ConsumerWidget {
  const DrawingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLayerPanelOpen = ref.watch(layerPanelOpenProvider);
    final isColorPickerOpen = ref.watch(colorPickerOpenProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main Drawing UI (without layer button in toolbar)
            Column(
              children: [
                ToolbarWidget(),
                const CanvasWidget(),
                const ControlsWidget(),
              ],
            ),

            // Color Picker Panel (Slides from left)
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

            // Floating Layer Button (Moves with panel)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: isLayerPanelOpen ? 320 + 4 : 4,
              top: MediaQuery.of(context).size.height / 2 - 28,
              child: FloatingActionButton(
                mini: true,
                onPressed: () {
                  ref.read(layerPanelOpenProvider.notifier).state =
                      !isLayerPanelOpen;
                },
                backgroundColor: Colors.teal,
                elevation: 8,
                shape: const CircleBorder(),
                child: Icon(
                  isLayerPanelOpen ? Icons.layers_clear : Icons.layers,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),

            // Floating Color Picker Button (Right side, below layer FAB)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: isLayerPanelOpen ? 320 + 4 : 4,
              top: MediaQuery.of(context).size.height / 2 + 36,
              child: FloatingActionButton(
                mini: true,
                onPressed: () {
                  ref.read(colorPickerOpenProvider.notifier).state =
                      !isColorPickerOpen;
                },
                backgroundColor: Colors.orange,
                elevation: 8,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.palette,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
