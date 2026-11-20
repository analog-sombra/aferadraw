import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/color_picker_provider.dart';
import 'compact_collapsible_presets.dart';

class ColorPickerPanelWidget extends ConsumerStatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const ColorPickerPanelWidget({
    required this.isOpen,
    required this.onClose,
    super.key,
  });

  @override
  ConsumerState<ColorPickerPanelWidget> createState() => _ColorPickerPanelWidgetState();
}

class _ColorPickerPanelWidgetState extends ConsumerState<ColorPickerPanelWidget> {
  final TextEditingController _paletteNameController = TextEditingController();
  final Map<String, bool> _paletteExpandedMap = {};

  @override
  void dispose() {
    _paletteNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorState = ref.watch(colorPickerProvider);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: widget.isOpen ? 0 : -280,
      top: 0,
      bottom: 0,
      width: 280,
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
                    'Color',
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

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Compact Collapsible Color Presets Selector
                    CompactCollapsiblePresetsSelector(),

                    // Hue Slider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: List<Color>.generate(
                                  360,
                                  (index) =>
                                      HSVColor.fromAHSV(1, index.toDouble(), 1, 1)
                                          .toColor(),
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 24,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 10,
                                    elevation: 0,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                ),
                                child: Slider(
                                  value: colorState.hue,
                                  min: 0,
                                  max: 360,
                                  onChanged: (value) {
                                    ref
                                        .read(colorPickerProvider.notifier)
                                        .setHue(value);
                                  },
                                  activeColor: Colors.transparent,
                                  inactiveColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Color Picker Gradient
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Color',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GradientColorPicker(
                            selectedColor: colorState.selectedColor,
                            hueValue: colorState.hue,
                            onColorChanged: (color) {
                              ref
                                  .read(colorPickerProvider.notifier)
                                  .setColor(color);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Saturation Slider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saturation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  HSVColor.fromAHSV(1, colorState.hue, 0, colorState.value)
                                      .toColor(),
                                  HSVColor.fromAHSV(1, colorState.hue, 1, colorState.value)
                                      .toColor(),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 20,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8,
                                    elevation: 0,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 10,
                                  ),
                                ),
                                child: Slider(
                                  value: colorState.saturation,
                                  min: 0,
                                  max: 1,
                                  onChanged: (value) {
                                    ref
                                        .read(colorPickerProvider.notifier)
                                        .setSaturation(value);
                                  },
                                  activeColor: Colors.transparent,
                                  inactiveColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Brightness/Value Slider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Brightness',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black,
                                  HSVColor.fromAHSV(1, colorState.hue, colorState.saturation, 1)
                                      .toColor(),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 20,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8,
                                    elevation: 0,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 10,
                                  ),
                                ),
                                child: Slider(
                                  value: colorState.value,
                                  min: 0,
                                  max: 1,
                                  onChanged: (value) {
                                    ref
                                        .read(colorPickerProvider.notifier)
                                        .setValue(value);
                                  },
                                  activeColor: Colors.transparent,
                                  inactiveColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Current Color Display
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Container(
                        width: double.infinity,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorState.selectedColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.grey[600]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '#${colorState.selectedColor.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}',
                            style: TextStyle(
                              color: _isLightColor(colorState.selectedColor)
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Generated Color Presets (Collapsible)
                    _buildCollapsibleSection(
                      title: 'Generated Presets',
                      isExpanded: colorState.presetsExpanded,
                      onToggle: () {
                        ref
                            .read(colorPickerProvider.notifier)
                            .togglePresetsExpanded();
                      },
                      child: colorState.generatedPresets.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Text(
                                'Select a color to generate presets',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 9,
                                ),
                              ),
                            )
                          : GridView.count(
                              crossAxisCount: 8,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 2,
                              crossAxisSpacing: 2,
                              childAspectRatio: 1.0,
                              children: colorState.generatedPresets
                                  .map(
                                    (color) => _colorButton(
                                      color,
                                      () => ref
                                          .read(colorPickerProvider.notifier)
                                          .setColor(color),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),

                    // Recently Used Colors
                    if (colorState.usedColors.isNotEmpty)
                      _buildCollapsibleSection(
                        title: 'Recently Used',
                        isExpanded: true,
                        onToggle: () {},
                        child: GridView.count(
                          crossAxisCount: 8,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 3,
                          crossAxisSpacing: 3,
                          childAspectRatio: 1.0,
                          children: colorState.usedColors
                              .take(40)
                              .map(
                                (color) => _colorButton(
                                  color,
                                  () => ref
                                      .read(colorPickerProvider.notifier)
                                      .setColor(color),
                                ),
                              )
                              .toList(),
                        ),
                      ),

                    // Custom Palettes Section
                    ..._buildCustomPalettesSection(ref, colorState),

                    // Create Palette Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: _buildPaletteButton(
                        icon: Icons.add,
                        label: 'Create Palette',
                        onPressed: () => _showCreatePaletteDialog(ref),
                        color: const Color(0xFF20B2AA),
                      ),
                    ),

                    // Add to Palette Button
                    if (colorState.customPalettes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: _buildPaletteButton(
                          icon: Icons.bookmark_add,
                          label: 'Add to Palette',
                          onPressed: () => _showAddColorDialog(ref, colorState),
                          color: const Color(0xFF663399),
                        ),
                      ),

                    // Reset Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: _buildPaletteButton(
                        icon: Icons.refresh,
                        label: 'Reset',
                        onPressed: () {
                          ref.read(colorPickerProvider.notifier).resetColor();
                        },
                        color: Colors.grey[700]!,
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: child,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCustomPalettesSection(
    WidgetRef ref,
    ColorPickerState colorState,
  ) {
    return colorState.customPalettes.entries.map((entry) {
      final paletteName = entry.key;
      final colors = entry.value;
      final isExpanded =
          _paletteExpandedMap.putIfAbsent(paletteName, () => true);

      return _buildCollapsibleSection(
        title: paletteName,
        isExpanded: isExpanded,
        onToggle: () {
          setState(() {
            _paletteExpandedMap[paletteName] = !isExpanded;
          });
        },
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.0,
              children: colors
                  .map(
                    (color) => Stack(
                      alignment: Alignment.topRight,
                      children: [
                        _colorButton(
                          color,
                          () => ref
                              .read(colorPickerProvider.notifier)
                              .setColor(color),
                        ),
                        GestureDetector(
                          onTap: () {
                            final updatedColors =
                                List<Color>.from(colors);
                            updatedColors.remove(color);
                            if (updatedColors.isEmpty) {
                              ref
                                  .read(colorPickerProvider.notifier)
                                  .removeCustomPalette(paletteName);
                            } else {
                              ref
                                  .read(colorPickerProvider.notifier)
                                  .addCustomPalette(paletteName, updatedColors);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red[700],
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.close,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                ref
                    .read(colorPickerProvider.notifier)
                    .removeCustomPalette(paletteName);
              },
              child: Text(
                'Delete Palette',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPaletteButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.grey[700]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorButton(Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: Colors.grey[600]!,
            width: 1,
          ),
        ),
      ),
    );
  }

  void _showCreatePaletteDialog(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Create Palette',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _paletteNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter palette name',
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = _paletteNameController.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(colorPickerProvider.notifier)
                    .addCustomPalette(name, []);
                _paletteNameController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(color: Color(0xFF20B2AA)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddColorDialog(WidgetRef ref, ColorPickerState colorState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Add to Palette',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: colorState.customPalettes.keys
                .map(
                  (paletteName) => ListTile(
                    title: Text(
                      paletteName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      ref
                          .read(colorPickerProvider.notifier)
                          .addColorToCustomPalette(
                            paletteName,
                            colorState.selectedColor,
                          );
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  bool _isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }
}

class GradientColorPicker extends StatefulWidget {
  final Color selectedColor;
  final double hueValue;
  final Function(Color) onColorChanged;

  const GradientColorPicker({
    required this.selectedColor,
    required this.hueValue,
    required this.onColorChanged,
    super.key,
  });

  @override
  State<GradientColorPicker> createState() => _GradientColorPickerState();
}

class _GradientColorPickerState extends State<GradientColorPicker> {
  late Offset _lastSelectPosition;

  @override
  void initState() {
    super.initState();
    _lastSelectPosition = const Offset(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        _updateColor(localPosition, renderBox.size);
      },
      onPanUpdate: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        _updateColor(localPosition, renderBox.size);
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[700]!, width: 1),
        ),
        child: CustomPaint(
          painter: HSVColorPickerPainter(hueValue: widget.hueValue),
          child: Stack(
            children: [
              Positioned(
                left: _lastSelectPosition.dx - 6,
                top: _lastSelectPosition.dy - 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateColor(Offset localPosition, Size size) {
    setState(() {
      _lastSelectPosition = Offset(
        localPosition.dx.clamp(0, size.width),
        localPosition.dy.clamp(0, size.height),
      );
    });

    final saturation = (_lastSelectPosition.dx / size.width).clamp(0.0, 1.0);
    final value = 1.0 - (_lastSelectPosition.dy / size.height).clamp(0.0, 1.0);

    final color = HSVColor.fromAHSV(1, widget.hueValue, saturation, value).toColor();
    widget.onColorChanged(color);
  }
}

class HSVColorPickerPainter extends CustomPainter {
  final double hueValue;

  HSVColorPickerPainter({required this.hueValue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final pureColor = HSVColor.fromAHSV(1, hueValue, 1, 1).toColor();

    final saturationGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, pureColor],
    );

    final saturationPaint = Paint()
      ..shader = saturationGradient.createShader(rect);
    canvas.drawRect(rect, saturationPaint);

    final brightnessGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    );

    final brightnessPaint = Paint()
      ..shader = brightnessGradient.createShader(rect);
    canvas.drawRect(rect, brightnessPaint);
  }

  @override
  bool shouldRepaint(HSVColorPickerPainter oldDelegate) {
    return oldDelegate.hueValue != hueValue;
  }
}
