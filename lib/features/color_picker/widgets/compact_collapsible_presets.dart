import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/palette_state_provider.dart';
import '../providers/color_picker_provider.dart';
import '../screens/palette_selector_page.dart';

class CompactCollapsiblePresetsSelector extends ConsumerWidget {
  const CompactCollapsiblePresetsSelector({super.key});

  void _openPaletteSelector(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PaletteSelectorPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletteState = ref.watch(paletteStateProvider);
    final selectedPalette = paletteState.selectedPalette;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedPalette?.isAI == true ? '✨ Palettes' : '🎨 Palettes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                GestureDetector(
                  onTap: () => _openPaletteSelector(context),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[600]!, width: 0.5),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.open_in_full, color: Colors.grey, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Browse',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Show Selected Palette
          if (selectedPalette != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Expanded(
                  //       child: Text(
                  //         selectedPalette.name,
                  //         style: TextStyle(
                  //           color:
                  //               selectedPalette.isAI
                  //                   ? Colors.cyan[400]
                  //                   : Colors.blue[400],
                  //           fontSize: 11,
                  //           fontWeight: FontWeight.w600,
                  //           letterSpacing: 0.5,
                  //         ),
                  //         maxLines: 1,
                  //         overflow: TextOverflow.ellipsis,
                  //       ),
                  //     ),
                  //     Text(
                  //       '(${selectedPalette.colors.length} colors)',
                  //       style: TextStyle(
                  //         color: Colors.grey[500],
                  //         fontSize: 9,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(
                      selectedPalette.colors.length,
                      (idx) {
                        final color = selectedPalette.colors[idx];
                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(colorPickerProvider.notifier)
                                .setColor(color);
                          },
                          child: Tooltip(
                            message: _colorToHex(color),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Colors.grey[600]!,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Empty State Message
          if (selectedPalette == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Browse to select a palette',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
