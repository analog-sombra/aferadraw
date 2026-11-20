import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/color_presets_provider.dart';
import '../providers/color_picker_provider.dart';

class CompactColorPresetSelector extends ConsumerWidget {
  const CompactColorPresetSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPresets = ref.watch(colorPresetsProvider);
    final selectedIndex = ref.watch(selectedPresetIndexProvider);
    final selectedPreset = ref.watch(selectedPresetProvider);
    final selectedColorIndex = ref.watch(selectedPresetColorProvider);

    return Column(
      children: [
        // Preset dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[700]!, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Color Presets',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[700]!, width: 0.5),
                ),
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: selectedIndex,
                  underline: const SizedBox(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  dropdownColor: Colors.grey[850],
                  items: List.generate(allPresets.length, (index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Row(
                        children: [
                          // Mini preview
                          SizedBox(
                            height: 16,
                            width: 60,
                            child: Row(
                              children: allPresets[index]
                                  .colors
                                  .take(5)
                                  .map(
                                    (color) => Flexible(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: color,
                                          border: Border.all(
                                            color: Colors.grey[700]!,
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              allPresets[index].name,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(selectedPresetIndexProvider.notifier).state = value;
                      // Set the first color from preset
                      if (allPresets[value].colors.isNotEmpty) {
                        ref
                            .read(colorPickerProvider.notifier)
                            .setColor(allPresets[value].colors[0]);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Preset colors grid
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[700]!, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedPreset.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${selectedPreset.colors.length} colors',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(
                  selectedPreset.colors.length,
                  (index) {
                    final color = selectedPreset.colors[index];
                    final isSelected = selectedColorIndex == index;

                    return GestureDetector(
                      onTap: () {
                        ref.read(selectedPresetColorProvider.notifier).state =
                            isSelected ? null : index;
                        // Set color when clicked
                        ref
                            .read(colorPickerProvider.notifier)
                            .setColor(color);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected
                              ? Border.all(
                                  color: Colors.white,
                                  width: 2,
                                )
                              : Border.all(
                                  color: Colors.grey[600]!,
                                  width: 0.5,
                                ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.6),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: _isLightColor(color)
                                    ? Colors.black
                                    : Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isLightColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }
}
