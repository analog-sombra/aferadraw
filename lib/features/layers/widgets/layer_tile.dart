import 'package:flutter/material.dart';
import '../models/layer_model.dart';

class LayerTile extends StatefulWidget {
  final Layer layer;
  final bool isActive;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onVisibilityToggle;
  final VoidCallback onLockToggle;
  final VoidCallback onDelete;
  final Function(String) onRename;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final Function(double) onOpacityChange;

  const LayerTile({
    super.key,
    required this.layer,
    required this.isActive,
    required this.index,
    required this.onTap,
    required this.onVisibilityToggle,
    required this.onLockToggle,
    required this.onDelete,
    required this.onRename,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onOpacityChange,
  });

  @override
  State<LayerTile> createState() => _LayerTileState();
}

class _LayerTileState extends State<LayerTile> {
  bool _isExpanded = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.layer.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showRenameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Layer'),
        content: TextField(
          controller: _nameController,
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
              widget.onRename(_nameController.text);
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isActive ? Colors.deepPurple.withOpacity(0.3) : Colors.transparent,
        border: Border.all(
          color: widget.isActive ? Colors.deepPurple : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Main Layer Tile
          GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Layer Type Icon
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      widget.layer.type == 'group' ? Icons.folder : Icons.image,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                  ),

                  // Layer Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.layer.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.layer.opacity < 1.0)
                          Text(
                            'Opacity: ${(widget.layer.opacity * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Visibility Toggle
                  IconButton(
                    icon: Icon(
                      widget.layer.isVisible ? Icons.visibility : Icons.visibility_off,
                      color: widget.layer.isVisible ? Colors.white : Colors.grey,
                      size: 18,
                    ),
                    onPressed: widget.onVisibilityToggle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  const SizedBox(width: 4),

                  // Lock Toggle
                  IconButton(
                    icon: Icon(
                      widget.layer.isLocked ? Icons.lock : Icons.lock_open,
                      color: widget.layer.isLocked ? Colors.orange : Colors.grey,
                      size: 18,
                    ),
                    onPressed: widget.layer.name == 'Background'
                        ? null
                        : widget.onLockToggle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  const SizedBox(width: 4),

                  // More Options
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Rename'),
                        onTap: _showRenameDialog,
                      ),
                      PopupMenuItem(
                        child: const Text('Move Up'),
                        onTap: widget.onMoveUp,
                      ),
                      PopupMenuItem(
                        child: const Text('Move Down'),
                        onTap: widget.onMoveDown,
                      ),
                      if (widget.layer.name != 'Background')
                        PopupMenuItem(
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          onTap: widget.onDelete,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable Opacity Slider
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Opacity',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    value: widget.layer.opacity,
                    onChanged: widget.onOpacityChange,
                    min: 0,
                    max: 1,
                    activeColor: Colors.deepPurple,
                    inactiveColor: Colors.grey[700],
                  ),
                ],
              ),
            ),

          // Expand/Collapse Button
          if (widget.isActive)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
