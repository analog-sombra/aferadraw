import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/drawing_provider.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingProvider = ref.watch(drawingNotifierProvider);
    final notifier = ref.read(drawingNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => notifier.setBrush(),
            icon: const Icon(Icons.brush),
            label: const Text('Brush'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  drawingProvider.isErasing ? Colors.grey : Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => notifier.setEraser(),
            icon: const Icon(Icons.cleaning_services),
            label: const Text('Eraser'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  drawingProvider.isErasing ? Colors.red : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => notifier.clear(),
            icon: const Icon(Icons.delete),
            label: const Text('Clear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => notifier.resetAll(),
            icon: const Icon(Icons.aspect_ratio),
            label: const Text('Reset'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
