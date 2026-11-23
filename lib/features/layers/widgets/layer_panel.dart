import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/layer_provider.dart';
import '../models/layer_model.dart';
import '../models/layer_canvas_model.dart';
import '../../../notifiers/enhanced_drawing_notifier.dart';
import 'layer_tile_compact.dart';
import 'layer_preview_overlay.dart';

class _LayerTreeNode {
  final Layer layer;
  final int index;
  int depth;
  final List<_LayerTreeNode> children;
  bool isExpanded;

  _LayerTreeNode({
    required this.layer,
    required this.index,
    required this.depth,
    this.children = const [],
    this.isExpanded = true,
  });
}

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
  late ScrollController _scrollController;
  final Map<String, bool> _expandedGroups = {};
  bool _dragOverRoot = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Build a tree structure from flat layer list
  List<_LayerTreeNode> _buildLayerHierarchy(LayerStack layerStack) {
    final nodes = <String, _LayerTreeNode>{};
    final rootNodes = <_LayerTreeNode>[];

    // Create nodes for all layers
    for (int i = 0; i < layerStack.layers.length; i++) {
      final layer = layerStack.layers[i];
      nodes[layer.id] = _LayerTreeNode(
        layer: layer,
        index: i,
        depth: 0,
        children: [],
        isExpanded: _expandedGroups[layer.id] ?? (layer.type == 'group'),
      );
    }

    // Organize hierarchy
    for (final node in nodes.values) {
      if (node.layer.parentId != null) {
        final parentNode = nodes[node.layer.parentId];
        if (parentNode != null) {
          node.depth = parentNode.depth + 1;
          parentNode.children.add(node);
        }
      } else {
        rootNodes.add(node);
      }
    }

    return rootNodes;
  }

  /// Flatten tree for display
  List<MapEntry<_LayerTreeNode, int>> _flattenTree(List<_LayerTreeNode> nodes) {
    final result = <MapEntry<_LayerTreeNode, int>>[];

    void traverse(List<_LayerTreeNode> nodeList) {
      for (final node in nodeList) {
        result.add(MapEntry(node, node.depth));
        if (node.isExpanded && node.children.isNotEmpty) {
          traverse(node.children);
        }
      }
    }

    traverse(nodes);
    return result;
  }

  void _showRenameDialog(
      BuildContext context, String currentName, Function(String) onRename) {
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

  void _showDeleteConfirm(
      BuildContext context, String layerName, VoidCallback onDelete) {
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

  Widget _buildLayerTreeView(
      LayerStack layerStack, LayerStackNotifier notifier) {
    final treeRoots = _buildLayerHierarchy(layerStack);
    final flatList = _flattenTree(treeRoots);

    return DragTarget<LayerDragData>(
      onWillAcceptWithDetails: (details) {
        final draggedIndex = details.data.index;
        final isGrouped = details.data.isGrouped;

        if (draggedIndex >= 0 && draggedIndex < layerStack.layers.length) {
          // Show RED highlight if layer is grouped (has a parent)
          if (isGrouped != _dragOverRoot) {
            setState(() {
              _dragOverRoot = isGrouped;
            });
          }
          return isGrouped; // Only accept if layer is grouped
        }
        return false;
      },
      onAcceptWithDetails: (details) {
        final draggedIndex = details.data.index;
        if (draggedIndex >= 0 && draggedIndex < layerStack.layers.length) {
          final draggedLayer = layerStack.layers[draggedIndex];
          // Remove from group if it has a parent
          if (draggedLayer.parentId != null &&
              draggedLayer.parentId!.isNotEmpty) {
            notifier.removeLayerFromGroup(draggedIndex);
          }
        }
        setState(() {
          _dragOverRoot = false;
        });
      },
      onLeave: (data) {
        setState(() {
          _dragOverRoot = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Column(
          children: [
            // RED ungroup drop zone at the top
            if (candidateData.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _dragOverRoot ? 40 : 0,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.3),
                  border: Border.all(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    'DROP HERE TO UNGROUP',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: flatList.length,
                itemBuilder: (context, index) {
                  final reverseIndex = flatList.length - 1 - index;
                  final entry = flatList[reverseIndex];
                  final node = entry.key;
                  final layer = node.layer;
                  final layerIndex = node.index;
                  final depth = node.depth;
                  final isActive = layerStack.activeLayerIndex == layerIndex;

                  return Padding(
                    padding: EdgeInsets.only(left: depth * 16.0),
                    child: LayerTileCompact(
                      layer: layer,
                      isActive: isActive,
                      index: layerIndex,
                      totalLayers: layerStack.layers.length,
                      isChild: depth > 0,
                      isDragOverRoot: _dragOverRoot && depth > 0,
                      onTap: () => notifier.selectLayer(layerIndex),
                      onVisibilityToggle: () =>
                          notifier.toggleVisibility(layerIndex),
                      onLockToggle: () => notifier.toggleLock(layerIndex),
                      onDelete: () => _showDeleteConfirm(
                        context,
                        layer.name,
                        () => notifier.deleteLayer(layerIndex),
                      ),
                      onRename: () => _showRenameDialog(
                        context,
                        layer.name,
                        (newName) => notifier.renameLayer(layerIndex, newName),
                      ),
                      onReorder: (oldIndex, newIndex) =>
                          notifier.reorderLayer(oldIndex, newIndex),
                      onDropOnGroup: (draggedIndex, groupIndex) {
                        final draggedLayer = layerStack.layers[draggedIndex];
                        // If dragged layer is already in a group, move it between groups
                        if (draggedLayer.parentId != null &&
                            draggedLayer.parentId!.isNotEmpty) {
                          notifier.moveLayerBetweenGroups(
                              draggedIndex, groupIndex);
                        } else {
                          // Otherwise, just add it to the group
                          notifier.addLayerToGroup(draggedIndex, groupIndex);
                        }
                        setState(() {
                          _dragOverRoot = false;
                        });
                      },
                      onToggleExpand: () {
                        setState(() {
                          _expandedGroups[layer.id] =
                              !(_expandedGroups[layer.id] ?? true);
                        });
                      },
                      onLongPressStart: (position, strokes) {
                        if (layer.type != 'group') {
                          setState(() {
                            _previewLayerId = layer.id;
                          });
                        }
                      },
                      onLongPressEnd: () {
                        setState(() {
                          _previewLayerId = null;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                notifier.setOpacity(
                                    layerStack.activeLayerIndex, value);
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
                        const Icon(Icons.layers_clear,
                            color: Colors.grey, size: 12),
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
                                  notifier.setBlendMode(
                                      layerStack.activeLayerIndex, value);
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

            // Layers List with Scroll Buttons
            Expanded(
              child: Column(
                children: [
                  // Top Scroll Button
                  Container(
                    width: double.infinity,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[800]!,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_drop_up,
                            color: Colors.teal, size: 16),
                        onPressed: () {
                          _scrollController.animateTo(
                            _scrollController.offset + 50,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                  // Layers List (Tree Structure)
                  Expanded(
                    child: Stack(
                      children: [
                        Scrollbar(
                          controller: _scrollController,
                          thickness: 6,
                          radius: const Radius.circular(4),
                          thumbVisibility: true,
                          child: _buildLayerTreeView(layerStack, notifier),
                        ),
                        // Preview Overlay - shown as floating widget in stack
                        if (_previewLayerId != null)
                          Positioned(
                            top: 10,
                            right: 6,
                            width: 120,
                            child:
                                _buildPreviewCard(drawingProvider, layerStack),
                          ),
                      ],
                    ),
                  ),
                  // Bottom Scroll Button
                  Container(
                    width: double.infinity,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey[800]!,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.teal, size: 16),
                        onPressed: () {
                          _scrollController.animateTo(
                            _scrollController.offset - 50,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer - Add Layer Buttons + Rename/Delete (LEFT AND RIGHT SIDES)
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
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT SIDE: Add Layer and Add Group buttons
                  Row(
                    children: [
                      Tooltip(
                        message: 'Add Layer',
                        child: IconButton(
                          onPressed: () => notifier.addBasicLayer(
                              'Layer ${layerStack.layers.length}'),
                          icon: const Icon(Icons.add_box_outlined,
                              color: Colors.teal, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Add Group',
                        child: IconButton(
                          onPressed: () => notifier.addGroupLayer(
                              'Group ${layerStack.layers.length}'),
                          icon: const Icon(Icons.create_new_folder_outlined,
                              color: Colors.deepPurple, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),

                  // RIGHT SIDE: Rename and Delete buttons (only if layer is selected and not Background)
                  if (activeLayer != null && activeLayer.name != 'Background')
                    Row(
                      children: [
                        Tooltip(
                          message: 'Rename Layer',
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.teal,
                              size: 18,
                            ),
                            onPressed: () => _showRenameDialog(
                              context,
                              activeLayer.name,
                              (newName) => notifier.renameLayer(
                                  layerStack.activeLayerIndex, newName),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Delete Layer',
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () => _showDeleteConfirm(
                              context,
                              activeLayer.name,
                              () => notifier
                                  .deleteLayer(layerStack.activeLayerIndex),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(
      EnhancedDrawingState drawingProvider, dynamic layerStack) {
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
      final layerCanvas =
          drawingProvider.layerCanvasStorage.getLayerCanvas(_previewLayerId!);
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
                    color:
                        layer.type == 'group' ? Colors.amber : Colors.grey[400],
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
                    : LayoutBuilder(
                        builder: (context, constraints) => CustomPaint(
                          painter: LayerPreviewPainter(
                            strokes: strokes,
                            opacity: layer!.opacity,
                            fitToView: true,
                          ),
                          size: Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
