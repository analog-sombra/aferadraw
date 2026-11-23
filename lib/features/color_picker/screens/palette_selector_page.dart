import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../color_preset_model.dart';
import '../providers/color_presets_provider.dart';
import '../providers/color_picker_provider.dart';
import '../providers/palette_state_provider.dart';
import '../services/ai_color_api_service.dart';
import 'package:logger/logger.dart';

class PaletteSelectorPage extends ConsumerStatefulWidget {
  const PaletteSelectorPage({super.key});

  @override
  ConsumerState<PaletteSelectorPage> createState() =>
      _PaletteSelectorPageState();
}

class _PaletteSelectorPageState extends ConsumerState<PaletteSelectorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  List<int> _filteredIndices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController();
    _updateFilteredList('');
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  void _selectPalette(int paletteIndex, ColorPreset preset) {
    // Use simple palette state provider
    ref.read(paletteStateProvider.notifier).selectPalette(
          preset.name,
          preset.colors,
          isAI: false,
        );

    // Set the first color in color picker
    if (preset.colors.isNotEmpty) {
      ref.read(colorPickerProvider.notifier).setColor(preset.colors[0]);
    }
    Navigator.of(context).pop();
  }

  void _selectApiPalette(ColorPalette palette) {
    // Convert API palette colors (hex strings) to Color objects
    final colors =
        palette.colors.map((hexColor) => _parseColor(hexColor)).toList();

    // Use simple palette state provider for AI palette
    ref.read(paletteStateProvider.notifier).selectPalette(
          palette.name,
          colors,
          isAI: true,
        );

    // Select first color
    if (colors.isNotEmpty) {
      ref.read(colorPickerProvider.notifier).setColor(colors[0]);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(colorPresetsProvider);
    final selectedIndex = ref.watch(selectedPresetIndexProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Select Color Palette',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Palettes'),
            Tab(text: 'AI Color'),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Local Palettes
          _buildLocalPalettesTab(presets, selectedIndex),
          // Tab 2: AI Color API Palettes
          _buildApiPalettesTab(),
        ],
      ),
    );
  }

  Widget _buildLocalPalettesTab(List<ColorPreset> presets, int selectedIndex) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: _updateFilteredList,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search palettes...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.grey, size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _updateFilteredList('');
                      },
                      child:
                          const Icon(Icons.clear, color: Colors.grey, size: 18),
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[900],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5),
              ),
            ),
          ),
        ),
        // Grid
        Expanded(
          child: _filteredIndices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        color: Colors.grey[600],
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No palettes found',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _filteredIndices.length,
                  itemBuilder: (context, idx) {
                    final paletteIdx = _filteredIndices[idx];
                    final preset = presets[paletteIdx];
                    final isSelected = paletteIdx == selectedIndex;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _selectPalette(paletteIdx, preset),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.grey[800] : Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[700]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.grey[700]!,
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: List.generate(
                                    preset.colors.length,
                                    (colorIdx) {
                                      return Expanded(
                                        child: Tooltip(
                                          message: _colorToHex(
                                              preset.colors[colorIdx]),
                                          child: Container(
                                            margin: EdgeInsets.only(
                                              right: colorIdx <
                                                      preset.colors.length - 1
                                                  ? 2
                                                  : 0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: preset.colors[colorIdx],
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildApiPalettesTab() {
    return Column(
      children: [
        // Search + Sort controls
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        ref.read(apiPaletteSearchProvider.notifier).state =
                            value;
                        ref.read(apiPalettePageProvider.notifier).state = 1;
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search AI Color palettes...',
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.grey, size: 18),
                        filled: true,
                        fillColor: Colors.grey[900],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              BorderSide(color: Colors.grey[700]!, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              BorderSide(color: Colors.grey[700]!, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Sort dropdown (compact, no label)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                    child: DropdownButton<String>(
                      underline: const SizedBox(),
                      dropdownColor: Colors.grey[850],
                      value: ref.watch(apiPaletteSortProvider),
                      items: const [
                        DropdownMenuItem(
                          value: 'popular',
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Text(
                              'Popular',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'trending',
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Text(
                              'Trending',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'newest',
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Text(
                              'Newest',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(apiPaletteSortProvider.notifier).state =
                              value;
                          ref.read(apiPalettePageProvider.notifier).state = 1;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Palettes grid
        Expanded(
          child: _buildApiPalettesGrid(),
        ),
      ],
    );
  }

  Widget _buildApiPalettesGrid() {
    final search = ref.watch(apiPaletteSearchProvider);
    final sort = ref.watch(apiPaletteSortProvider);
    final page = ref.watch(apiPalettePageProvider);
    final tag = ref.watch(apiPaletteTagProvider);

    final palettesAsync = ref.watch(
      apiPalettesProvider((
        tag: tag,
        query: search,
        sort: sort,
        page: page,
        limit: 20,
      )),
    );

    return palettesAsync.when(
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading palettes...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey[600],
              size: 48,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Failed to load palettes\n${error.toString()}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(apiPalettesProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (response) => Column(
        children: [
          // Grid
          Expanded(
            child: response.data.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          color: Colors.grey[600],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No palettes found',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: response.data.length,
                    itemBuilder: (context, idx) {
                      final palette = response.data[idx];
                      // log the palette

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          print('[DEBUG] Palette selected: ${palette.name}');
                          var logger = Logger();
                          logger.d("Selected palette: ${palette.name}");
                          _selectApiPalette(palette);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[700]!,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      palette.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Tags
                              if (palette.tags.isNotEmpty)
                                Wrap(
                                  spacing: 4,
                                  children: palette.tags
                                      .take(3)
                                      .map(
                                        (tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            border: Border.all(
                                              color: Colors.blue
                                                  .withValues(alpha: 0.5),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              const SizedBox(height: 8),
                              // Color strip
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.grey[700]!,
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: List.generate(
                                      palette.colors.length,
                                      (colorIdx) {
                                        final color = _parseColor(
                                            palette.colors[colorIdx]);
                                        return Expanded(
                                          child: Tooltip(
                                            message: palette.colors[colorIdx],
                                            child: Container(
                                              margin: EdgeInsets.only(
                                                right: colorIdx <
                                                        palette.colors.length -
                                                            1
                                                    ? 2
                                                    : 0,
                                              ),
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${palette.colors.length} colors',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.favorite_outline,
                                        color: Colors.red,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${palette.likes}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Pagination with info text
          if (response.totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: page > 1
                        ? () => ref
                            .read(apiPalettePageProvider.notifier)
                            .state = page - 1
                        : null,
                    child: const Text('← Previous'),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[700]!, width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Showing ${response.data.length} of ${response.total}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Page $page of ${response.totalPages}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: page < response.totalPages
                        ? () => ref
                            .read(apiPalettePageProvider.notifier)
                            .state = page + 1
                        : null,
                    child: const Text('Next →'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
