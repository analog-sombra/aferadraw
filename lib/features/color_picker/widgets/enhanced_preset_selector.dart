import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../color_preset_model.dart';
import '../providers/color_presets_provider.dart';
import '../providers/color_picker_provider.dart';

class EnhancedPresetSelector extends ConsumerStatefulWidget {
  const EnhancedPresetSelector({super.key});

  @override
  ConsumerState<EnhancedPresetSelector> createState() =>
      _EnhancedPresetSelectorState();
}

class _EnhancedPresetSelectorState
    extends ConsumerState<EnhancedPresetSelector> {
  late TextEditingController _searchController;
  List<int> _filteredIndices = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _updateFilteredList('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredList(String query) {
    final presets = ref.read(colorPresetsProvider);
    if (query.isEmpty) {
      _filteredIndices = List.generate(presets.length, (i) => i);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredIndices = [];
      for (int i = 0; i < presets.length; i++) {
        if (presets[i].name.toLowerCase().contains(lowerQuery)) {
          _filteredIndices.add(i);
        }
      }
    }
    setState(() {});
  }

  void _selectColor(Color color) {
    ref.read(colorPickerProvider.notifier).setColor(color);
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(colorPresetsProvider);
    final selectedIndex = ref.watch(selectedPresetIndexProvider);
    final selectedPreset = presets.isNotEmpty ? presets[selectedIndex] : null;

    return SingleChildScrollView(
      child: Container(
        color: Colors.grey[900],
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  '🎨 Color Palettes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_filteredIndices.length} palettes',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Search bar
            TextField(
              controller: _searchController,
              onChanged: _updateFilteredList,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search palettes...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _updateFilteredList('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[850],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Palettes Grid
            if (_filteredIndices.isNotEmpty)
              Column(
                children: [
                  for (int idx = 0; idx < _filteredIndices.length; idx += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          // First palette
                          Expanded(
                            child: _buildPaletteCard(
                              presets[_filteredIndices[idx]],
                              _filteredIndices[idx],
                              selectedIndex,
                              ref,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Second palette (if exists)
                          if (idx + 1 < _filteredIndices.length)
                            Expanded(
                              child: _buildPaletteCard(
                                presets[_filteredIndices[idx + 1]],
                                _filteredIndices[idx + 1],
                                selectedIndex,
                                ref,
                              ),
                            )
                          else
                            Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                    ),
                ],
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No palettes found',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Selected Palette Preview (if any palette is selected)
            if (selectedPreset != null && selectedPreset.colors.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[700]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              selectedPreset.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Spacer(),
                            Text(
                              '${selectedPreset.colors.length} colors',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Large color grid
                        GridView.count(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: List.generate(
                            selectedPreset.colors.length,
                            (index) {
                              final color = selectedPreset.colors[index];
                              return _buildColorBox(color, index);
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
      ),
    );
  }

  Widget _buildPaletteCard(
    ColorPreset preset,
    int index,
    int selectedIndex,
    WidgetRef ref,
  ) {
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () {
        ref.read(selectedPresetIndexProvider.notifier).state = index;
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[800] : Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[700]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Palette name
            Text(
              preset.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Mini color preview (5 colors in a row)
            Row(
              children: List.generate(
                preset.colors.length,
                (colorIndex) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(selectedPresetIndexProvider.notifier).state =
                            index;
                        _selectColor(preset.colors[colorIndex]);
                      },
                      child: Tooltip(
                        message: _colorToHex(preset.colors[colorIndex]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          height: 36,
                          decoration: BoxDecoration(
                            color: preset.colors[colorIndex],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.grey[600]!,
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            // Description
            Text(
              preset.description,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Widget _buildColorBox(Color color, int index) {
    return GestureDetector(
      onTap: () => _selectColor(color),
      child: Tooltip(
        message: _colorToHex(color),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[600]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectColor(color),
              borderRadius: BorderRadius.circular(6),
              child: Center(
                child: Text(
                  _colorToHex(color),
                  style: TextStyle(
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
