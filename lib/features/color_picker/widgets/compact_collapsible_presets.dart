import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/color_presets_provider.dart';
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
    final presets = ref.watch(colorPresetsProvider);
    final selectedIndex = ref.watch(selectedPresetIndexProvider);
    final selectedPreset = presets.isNotEmpty ? presets[selectedIndex] : null;
    final colorState = ref.watch(colorPickerProvider);
    final customPalettes = colorState.customPalettes;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        children: [
          // Header - Opens full-screen palette page
          GestureDetector(
            onTap: () => _openPaletteSelector(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '🎨 Palettes',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(992)',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.open_in_full,
                    color: Colors.grey,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Custom Palettes Section - SHOW FIRST
          if (customPalettes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📌 My AI Palettes',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: customPalettes.entries.map((entry) {
                      final paletteName = entry.key;
                      final colors = entry.value;
                      return Tooltip(
                        message: paletteName,
                        child: GestureDetector(
                          onTap: () {
                            if (colors.isNotEmpty) {
                              ref
                                  .read(colorPickerProvider.notifier)
                                  .setColor(colors[0]);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.blue[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (int i = 0; i < (colors.length > 3 ? 3 : colors.length); i++)
                                  Container(
                                    width: 14,
                                    height: 14,
                                    margin: EdgeInsets.only(
                                      right: i < (colors.length > 3 ? 2 : colors.length - 1) ? 2 : 0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors[i],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                if (colors.length > 3)
                                  const SizedBox(width: 2),
                                if (colors.length > 3)
                                  Text(
                                    '+${colors.length - 3}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 8,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Selected Palette Preview
          if (selectedPreset != null && selectedPreset.colors.isNotEmpty)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPreset.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: List.generate(
                          selectedPreset.colors.length,
                          (idx) {
                            final color = selectedPreset.colors[idx];
                            return GestureDetector(
                              onTap: () {
                                ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(color);
                              },
                              child: Tooltip(
                                message: _colorToHex(color),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.grey[600]!,
                                      width: 0.5,
                                    ),
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
              ],
            ),
        ],
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
