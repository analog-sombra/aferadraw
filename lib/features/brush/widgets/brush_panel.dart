import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brush_model.dart';
import '../providers/brush_provider.dart';
import 'brush_preview_painter.dart';

class BrushPanelWidget extends ConsumerStatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const BrushPanelWidget({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  @override
  ConsumerState<BrushPanelWidget> createState() => _BrushPanelWidgetState();
}

class _BrushPanelWidgetState extends ConsumerState<BrushPanelWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentBrush = ref.watch(brushProvider);
    final brushesByType = ref.watch(brushesByTypeProvider);
    final brushTypes = [
      'sketching',
      'painting',
      'ink',
      'watercolor',
      'charcoal',
      'chalk',
      'airbrush',
      'texture',
    ];

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: widget.isOpen ? 0 : -300,
      top: 0,
      bottom: 0,
      width: 300,
      child: Container(
        color: const Color(0xFF1E1E1E),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[700]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Brushes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Tabs for brush types
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: brushTypes
                  .map((type) => Tab(
                        text: type[0].toUpperCase() + type.substring(1),
                      ))
                  .toList(),
            ),

            // Brush list
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: brushTypes.map((type) {
                  final brushesOfType = brushesByType[type] ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: brushesOfType.length,
                    itemBuilder: (context, index) {
                      final brush = brushesOfType[index];
                      final isSelected = currentBrush.id == brush.id;

                      return GestureDetector(
                        onTap: () {
                          ref.read(brushProvider.notifier).selectBrush(brush);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.withAlpha(100)
                                : Colors.grey[800],
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey[700]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // Brush preview
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.grey[700]!,
                                    width: 1,
                                  ),
                                ),
                                child: CustomPaint(
                                  painter: BrushPreviewPainter(brush: brush),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Brush info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      brush.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Size: ${brush.defaultSize.toStringAsFixed(1)}',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Hard: ${(brush.hardness * 100).toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 10,
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
                    },
                  );
                }).toList(),
              ),
            ),

            // Current brush details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[700]!,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current: ${currentBrush.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Size slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Size: ${currentBrush.defaultSize.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                      Slider(
                        value: currentBrush.defaultSize,
                        min: 1,
                        max: 100,
                        onChanged: (value) {
                          ref
                              .read(brushProvider.notifier)
                              .updateSize(value);
                        },
                      ),
                    ],
                  ),

                  // Opacity slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opacity: ${(currentBrush.defaultOpacity * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                      Slider(
                        value: currentBrush.defaultOpacity,
                        min: 0,
                        max: 1,
                        onChanged: (value) {
                          ref
                              .read(brushProvider.notifier)
                              .updateOpacity(value);
                        },
                      ),
                    ],
                  ),

                  // Hardness slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hardness: ${(currentBrush.hardness * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                      Slider(
                        value: currentBrush.hardness,
                        min: 0,
                        max: 1,
                        onChanged: (value) {
                          ref
                              .read(brushProvider.notifier)
                              .updateHardness(value);
                        },
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
}
