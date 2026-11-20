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

    final showAI = customPalettes.isNotEmpty;
    final showNormal = selectedPreset != null && customPalettes.isEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        children: [
          // Header without Toggle Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  showAI ? '✨ AI Palettes' : '🎨 Palettes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                GestureDetector(
                  onTap: () => _openPaletteSelector(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

          // Show ONLY AI Palettes
          if (showAI)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📌 My AI Palettes',
                    style: TextStyle(
                      color: Colors.cyan[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: customPalettes.entries.map((entry) {
                      final paletteName = entry.key;
                      final colors = entry.value;
                      return Tooltip(
                        message: paletteName,
                        child: GestureDetector(
                          onTap: () {
                            if (colors.isNotEmpty) {
                              ref.read(colorPickerProvider.notifier).setColor(colors[0]);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.cyan[500]!,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyan[700]!.withOpacity(0.2),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (int i = 0;
                                    i < (colors.length > 4 ? 4 : colors.length);
                                    i++)
                                  Container(
                                    width: 16,
                                    height: 16,
                                    margin: EdgeInsets.only(
                                      right: i <
                                              (colors.length > 4 ? 3 : colors.length - 1)
                                          ? 2
                                          : 0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors[i],
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(
                                        color: Colors.grey[800]!,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                if (colors.length > 4) ...[
                                  const SizedBox(width: 2),
                                  Text(
                                    '+${colors.length - 4}',
                                    style: TextStyle(
                                      color: Colors.cyan[400],
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ]
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

          // Show ONLY Normal Palettes
          if (showNormal)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedPreset!.name,
                          style: TextStyle(
                            color: Colors.blue[400],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '(${selectedPreset.colors.length} colors)',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(
                      selectedPreset.colors.length,
                      (idx) {
                        final color = selectedPreset.colors[idx];
                        return GestureDetector(
                          onTap: () {
                            ref.read(colorPickerProvider.notifier).setColor(color);
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
                                    color: color.withOpacity(0.3),
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
          if (!showAI && !showNormal)
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
                    customPalettes.isEmpty
                        ? 'Select from Browse to add AI Palettes'
                        : 'Select a view mode above',
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
    return '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
