import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/layer_provider.dart';
import '../models/layer_model.dart';
import '../models/layer_canvas_model.dart';
import '../../../notifiers/enhanced_drawing_notifier.dart';
import 'layer_tile_compact.dart';
import 'layer_preview_overlay.dart';

class LayerPanelWidget extends ConsumerStatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const LayerPanelWidget({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  @override
  ConsumerState<LayerPanelWidget> createState() => _LayerPanelWidgetState();
}

class _LayerPanelWidgetState extends ConsumerState<LayerPanelWidget> {
  String? _previewLayerId;

  void _showRenameDialog(BuildContext context, String currentName, Function(String) onRename) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Layer'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Layer name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onRename(nameController.text);
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String layerName, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Layer'),
        content: Text('Delete "$layerName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layerStack = ref.watch(layerStackProvider);
    final notifier = ref.read(layerStackProvider.notifier);
    final drawingProvider = ref.watch(enhancedDrawingNotifierProvider);
    final activeLayer = layerStack.activeLayer;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: widget.isOpen ? 0 : -320,
      top: 0,
      bottom: 0,
      width: 320,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[800]!,
                    width: 1,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Layers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Selected Layer Options (Opacity & other properties)
            if (activeLayer != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[800]!,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Layer Name
                    Text(
                      'Selected: ${activeLayer.name}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Opacity Slider
                    Row(
                      children: [
                        const Icon(Icons.opacity, color: Colors.grey, size: 12),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SizedBox(
                            height: 20,
                            child: Slider(
                              value: activeLayer.opacity,
                              onChanged: (value) {
                                notifier.setOpacity(layerStack.activeLayerIndex, value);
                              },
                              min: 0.0,
                              max: 1.0,
                              activeColor: Colors.teal,
                              inactiveColor: Colors.grey[600],
                            ),
                          ),
                        ),
                        Text(
                          '${(activeLayer.opacity * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Blend Mode Dropdown
                    Row(
                      children: [
                        const Icon(Icons.layers_clear, color: Colors.grey, size: 12),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: DropdownButton<BlendMode>(
                              value: activeLayer.blendMode,
                              isDense: true,
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor: Colors.grey[800],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: BlendMode.srcOver,
                                  child: Text('Normal'),
                                ),
                                DropdownMenuItem(
                                  value: BlendMode.multiply,
                                  child: Text('Multiply'),
                                ),
                                DropdownMenuItem(
                                  value: BlendMode.screen,
                                  child: Text('Screen'),
                                ),
                                DropdownMenuItem(
                                  value: BlendMode.overlay,
                                  child: Text('Overlay'),
                                ),
                                DropdownMenuItem(
                                  value: BlendMode.darken,
                                  child: Text('Darken'),
                                ),
                                DropdownMenuItem(
                                  value: BlendMode.lighten,
                                  child: Text('Lighten'),
                                ),
                                DropdownMenuItem(
                                  value: BlendMode.colorDodge,
                                  child: Text('Color Dodge'),
                                ),
                                DropdownMenuItem(
                                  value: BlendMode.colorBurn,
                                  child: Text('Color Burn'),
                                ),
                              ],
                              onChanged: (BlendMode? value) {
                                if (value != null) {
                                  notifier.setBlendMode(layerStack.activeLayerIndex, value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Lock/Visibility Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activeLayer.isLocked ? '🔒 Locked' : '🔓 Unlocked',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Text(
                          activeLayer.isVisible ? '👁 Visible' : '🚫 Hidden',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Layers List
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: layerStack.layers.length,
                    itemBuilder: (context, index) {
                      final reverseIndex = layerStack.layers.length - 1 - index;
                      final layer = layerStack.layers[reverseIndex];
                      final isActive = layerStack.activeLayerIndex == reverseIndex;

                      return LayerTileCompact(
                        layer: layer,
                        isActive: isActive,
                        index: reverseIndex,
                        totalLayers: layerStack.layers.length,
                        onTap: () => notifier.selectLayer(reverseIndex),
                        onVisibilityToggle: () => notifier.toggleVisibility(reverseIndex),
                        onLockToggle: () => notifier.toggleLock(reverseIndex),
                        onDelete: () => _showDeleteConfirm(
                          context,
                          layer.name,
                          () => notifier.deleteLayer(reverseIndex),
                        ),
                        onRename: () => _showRenameDialog(
                          context,
                          layer.name,
                          (newName) => notifier.renameLayer(reverseIndex, newName),
                        ),
                        onReorder: (oldIndex, newIndex) => notifier.reorderLayer(oldIndex, newIndex),
                        onDropOnGroup: (draggedIndex, groupIndex) {
                          notifier.addLayerToGroup(draggedIndex, groupIndex);
                        },
                        onToggleExpand: () {
                          // Handle group expansion
                        },
                        onLongPressStart: (position, strokes) {
                          // Show preview when long-pressing
                          setState(() {
                            _previewLayerId = layer.id;
                          });
                        },
                        onLongPressEnd: () {
                          // Hide preview on release
                          setState(() {
                            _previewLayerId = null;
                          });
                        },
                      );
                    },
                  ),
                  // Preview Overlay - shown as floating widget in stack
                  if (_previewLayerId != null)
                    Positioned(
                      top: 10,
                      left: 6,
                      right: 6,
                      child: _buildPreviewCard(drawingProvider, layerStack),
                    ),
                ],
              ),
            ),

            // Footer - Add Layer Buttons (LEFT SIDE) - Icon only
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[800]!,
                    width: 0.5,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Tooltip(
                    message: 'Add Layer',
                    child: IconButton(
                      onPressed: () => notifier.addBasicLayer('Layer ${layerStack.layers.length}'),
                      icon: const Icon(Icons.add_box_outlined, color: Colors.teal, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Add Group',
                    child: IconButton(
                      onPressed: () => notifier.addGroupLayer('Group ${layerStack.layers.length}'),
                      icon: const Icon(Icons.create_new_folder_outlined, color: Colors.deepPurple, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(EnhancedDrawingState drawingProvider, dynamic layerStack) {
    Layer? layer;
    try {
      layer = layerStack.layers.firstWhere((l) => l.id == _previewLayerId);
    } catch (e) {
      layer = null;
    }
    if (layer == null) return const SizedBox.shrink();

    // Get strokes from canvas storage
    List<LayerStroke> strokes = [];
    try {
      final layerCanvas = drawingProvider.layerCanvasStorage.getLayerCanvas(_previewLayerId!);
      strokes = List.from(layerCanvas.strokes);
    } catch (e) {
      strokes = [];
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 120,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.deepPurple, width: 1),
        ),
        child: Column(
          children: [
            // Header with layer info
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[700]!, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    layer.type == 'group' ? Icons.folder : Icons.image,
                    color: layer.type == 'group' ? Colors.amber : Colors.grey[400],
                    size: 10,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          layer.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          'Strokes: ${strokes.length}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Preview canvas - expanded to fill available space
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                ),
                child: strokes.isEmpty
                    ? Center(
                        child: Text(
                          'Empty',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: LayerPreviewPainter(
                          strokes: strokes,
                          opacity: layer.opacity,
                          fitToView: true,
                        ),
                        size: Size.infinite,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

