import 'package:flutter/material.dart';
import '../models/layer_model.dart';
import '../models/layer_canvas_model.dart';

class LayerDragData {
  final int index;
  final bool isGrouped;
  
  LayerDragData({required this.index, required this.isGrouped});
}

class LayerTileCompact extends StatefulWidget {
  final Layer layer;
  final bool isActive;
  final int index;
  final int totalLayers;
  final bool isChild;
  final VoidCallback onTap;
  final VoidCallback onVisibilityToggle;
  final VoidCallback onLockToggle;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(int layerIndex, int groupIndex)? onDropOnGroup;
  final VoidCallback onToggleExpand;
  final Function(Offset position, List<LayerStroke> strokes)? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final VoidCallback? onDropToRoot;
  final bool isDragOverRoot;

  const LayerTileCompact({
    super.key,
    required this.layer,
    required this.isActive,
    required this.index,
    required this.totalLayers,
    this.isChild = false,
    required this.onTap,
    required this.onVisibilityToggle,
    required this.onLockToggle,
    required this.onDelete,
    required this.onRename,
    required this.onReorder,
    this.onDropOnGroup,
    required this.onToggleExpand,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.onDropToRoot,
    this.isDragOverRoot = false,
  });

  @override
  State<LayerTileCompact> createState() => _LayerTileCompactState();
}

class _LayerTileCompactState extends State<LayerTileCompact> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.layer.type == 'group' ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<LayerDragData>(
      data: LayerDragData(
        index: widget.index,
        isGrouped: widget.layer.parentId != null && widget.layer.parentId!.isNotEmpty,
      ),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.5),
            border: Border.all(color: Colors.deepPurple),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (widget.layer.type == 'group')
                Icon(_isExpanded ? Icons.folder_open : Icons.folder,
                    color: Colors.amber, size: 12),
              if (widget.layer.type != 'group')
                const Icon(Icons.image, color: Colors.grey, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.layer.name,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      child: DragTarget<LayerDragData>(
        onWillAcceptWithDetails: (details) {
          // Accept grouped layers only if dropping on a group
          if (details.data.isGrouped) {
            return widget.layer.type == 'group' && details.data.index != widget.index;
          }
          return true;
        },
        onAcceptWithDetails: (details) {
          final draggedLayerIndex = details.data.index;
          // If dropping on a group, add to group instead of reordering
          if (widget.layer.type == 'group' && draggedLayerIndex != widget.index) {
            // If dragged layer is grouped, use moveLayerBetweenGroups to handle both removal and addition
            if (details.data.isGrouped) {
              widget.onDropOnGroup?.call(draggedLayerIndex, widget.index);
              // Note: The parent widget (layer_panel) needs to be updated to call moveLayerBetweenGroups
            } else {
              widget.onDropOnGroup?.call(draggedLayerIndex, widget.index);
            }
          } else {
            widget.onReorder(draggedLayerIndex, widget.index);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isGroupTarget = widget.layer.type == 'group';
          final isDraggedOverThisLayer = candidateData.isNotEmpty;
          final shouldHighlightAsGroupTarget = isDraggedOverThisLayer && isGroupTarget;
          
          return GestureDetector(
            onTap: widget.onTap,
            onLongPressStart: (details) {
              if (widget.onLongPressStart != null && widget.layer.type != 'group') {
                widget.onLongPressStart!(details.globalPosition, []);
              }
            },
            onLongPressEnd: (details) {
              if (widget.onLongPressEnd != null) {
                widget.onLongPressEnd!();
              }
            },
            child: Container(
              margin: EdgeInsets.only(
                left: widget.isChild ? 20 : 6,
                right: 6,
                top: 2,
                bottom: 2,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? Colors.deepPurple.withValues(alpha: 0.4)
                    : (shouldHighlightAsGroupTarget
                        ? Colors.amber.withValues(alpha: 0.6)
                        : (widget.isDragOverRoot && widget.isChild
                            ? Colors.red.withValues(alpha: 0.4) // Red for ungroup target
                            : (isDraggedOverThisLayer
                                ? Colors.grey.withValues(alpha: 0.2)
                                : Colors.transparent))),
                border: Border.all(
                  color: widget.isActive
                      ? Colors.deepPurple
                      : (shouldHighlightAsGroupTarget
                          ? Colors.amber
                          : (widget.isDragOverRoot && widget.isChild
                              ? Colors.red
                              : Colors.transparent)),
                  width: (shouldHighlightAsGroupTarget || (widget.isDragOverRoot && widget.isChild)) ? 2.5 : 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Expand/Collapse for groups
                  if (widget.layer.type == 'group')
                    SizedBox(
                      width: 16,
                      height: 20,
                      child: IconButton(
                        icon: Icon(
                          _isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.amber,
                          size: 12,
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                          widget.onToggleExpand();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    )
                  else
                    const SizedBox(width: 16),

                  // Layer Icon
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      widget.layer.type == 'group' ? Icons.folder : Icons.image,
                      color: widget.layer.type == 'group'
                          ? Colors.amber
                          : Colors.grey[400],
                      size: 14,
                    ),
                  ),

                  // Layer Name
                  Expanded(
                    child: Text(
                      widget.layer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  // Visibility Toggle
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: IconButton(
                      icon: Icon(
                        widget.layer.isVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey[300],
                        size: 12,
                      ),
                      onPressed: widget.onVisibilityToggle,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),

                  // Lock Toggle
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: IconButton(
                      icon: Icon(
                        widget.layer.isLocked ? Icons.lock : Icons.lock_open,
                        color: widget.layer.isLocked
                            ? Colors.orange
                            : Colors.grey[300],
                        size: 12,
                      ),
                      onPressed: widget.onLockToggle,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

