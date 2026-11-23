import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/color_presets_provider.dart';

class ColorPresetSelector extends ConsumerStatefulWidget {
  final Function(List<Color>) onPresetSelected;
  final Function(Color)? onColorSelected;

  const ColorPresetSelector({
    super.key,
    required this.onPresetSelected,
    this.onColorSelected,
  });

  @override
  ConsumerState<ColorPresetSelector> createState() =>
      _ColorPresetSelectorState();
}

class _ColorPresetSelectorState extends ConsumerState<ColorPresetSelector> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPresets = ref.watch(colorPresetsProvider);
    final selectedIndex = ref.watch(selectedPresetIndexProvider);
    final selectedPreset = ref.watch(selectedPresetProvider);
    final selectedColorIndex = ref.watch(selectedPresetColorProvider);

    // Filter presets based on search
    final filteredPresets = _searchQuery.isEmpty
        ? allPresets
        : allPresets
            .where((preset) =>
                preset.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText:
                  'Search presets... (${filteredPresets.length}/${allPresets.length})',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),

        // Presets dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: DropdownButton<int>(
              isExpanded: true,
              value: selectedIndex,
              underline: const SizedBox(),
              items: List.generate(filteredPresets.length, (index) {
                final originalIndex =
                    allPresets.indexOf(filteredPresets[index]);
                return DropdownMenuItem<int>(
                  value: originalIndex,
                  child: Row(
                    children: [
                      // Mini preview
                      SizedBox(
                        height: 20,
                        child: Row(
                          children: filteredPresets[index]
                              .colors
                              .take(5)
                              .map(
                                (color) => Flexible(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          filteredPresets[index].name,
                          style: const TextStyle(fontSize: 11),
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
                  widget.onPresetSelected(allPresets[value].colors);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Large preset preview
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preset name and info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedPreset.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${selectedPreset.colors.length} colors',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Color grid
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(
                    selectedPreset.colors.length,
                    (index) {
                      final color = selectedPreset.colors[index];
                      final isSelected = selectedColorIndex == index;

                      return GestureDetector(
                        onTap: () {
                          ref.read(selectedPresetColorProvider.notifier).state =
                              isSelected ? null : index;
                          if (widget.onColorSelected != null) {
                            widget.onColorSelected!(color);
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                            border: isSelected
                                ? Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  )
                                : Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: isSelected
                              ? Center(
                                  child: Icon(
                                    Icons.check,
                                    color: _isLightColor(color)
                                        ? Colors.black
                                        : Colors.white,
                                    size: 24,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Hex code display
                if (selectedColorIndex != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Color:',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color:
                                    selectedPreset.colors[selectedColorIndex],
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _colorToHex(
                                selectedPreset.colors[selectedColorIndex],
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w500,
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
        ),

        const SizedBox(height: 10),

        // Info section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              'Total Presets: ${allPresets.length} | Available: ${filteredPresets.length}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isLightColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }
}
