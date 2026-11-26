import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/brush_provider.dart';

class BrushPanelWidget extends ConsumerWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const BrushPanelWidget({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBrush = ref.watch(brushProvider);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: isOpen ? 0 : -300,
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
                    'Brush Settings',
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
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Controls section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brush Options section
                    const Text(
                      'Brush Options',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Size slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Size',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                currentBrush.defaultSize.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: currentBrush.defaultSize,
                            min: 1,
                            max: 100,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey[700],
                            onChanged: (value) {
                              ref
                                  .read(brushProvider.notifier)
                                  .updateSize(value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Opacity slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Opacity',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(currentBrush.defaultOpacity * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: currentBrush.defaultOpacity,
                            min: 0,
                            max: 1,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey[700],
                            onChanged: (value) {
                              ref
                                  .read(brushProvider.notifier)
                                  .updateOpacity(value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Flow slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Flow',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(currentBrush.flow * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: currentBrush.flow,
                            min: 0,
                            max: 1,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey[700],
                            onChanged: (value) {
                              ref
                                  .read(brushProvider.notifier)
                                  .updateFlow(value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Stabilizer section
                    const Text(
                      'Stabilizer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Amount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (currentBrush.stabilizer * 100).toStringAsFixed(0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: currentBrush.stabilizer,
                            min: 0,
                            max: 1,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey[700],
                            onChanged: (value) {
                              ref
                                  .read(brushProvider.notifier)
                                  .updateStabilizer(value);
                            },
                          ),
                        ),
                      ],
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


