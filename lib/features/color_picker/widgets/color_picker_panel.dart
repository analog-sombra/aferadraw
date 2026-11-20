import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/color_picker_provider.dart';

class ColorPickerPanelWidget extends ConsumerWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const ColorPickerPanelWidget({
    required this.isOpen,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorState = ref.watch(colorPickerProvider);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: isOpen ? 0 : -280,
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
                    onPressed: onClose,
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

                    // Preset Colors
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.grey[700]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Presets',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GridView.count(
                            crossAxisCount: 8,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 1.0,
                            children: [
                              _presetColorButton(
                                Colors.red,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.red),
                              ),
                              _presetColorButton(
                                Colors.orange,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.orange),
                              ),
                              _presetColorButton(
                                Colors.yellow,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.yellow),
                              ),
                              _presetColorButton(
                                Colors.green,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.green),
                              ),
                              _presetColorButton(
                                Colors.teal,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.teal),
                              ),
                              _presetColorButton(
                                Colors.blue,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.blue),
                              ),
                              _presetColorButton(
                                Colors.purple,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.purple),
                              ),
                              _presetColorButton(
                                Colors.pink,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.pink),
                              ),
                              _presetColorButton(
                                Colors.brown,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.brown),
                              ),
                              _presetColorButton(
                                Colors.grey,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.grey),
                              ),
                              _presetColorButton(
                                Colors.black,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.black),
                              ),
                              _presetColorButton(
                                Colors.white,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.white),
                              ),
                              _presetColorButton(
                                Colors.red[300]!,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.red[300]!),
                              ),
                              _presetColorButton(
                                Colors.orange[300]!,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.orange[300]!),
                              ),
                              _presetColorButton(
                                Colors.green[300]!,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.green[300]!),
                              ),
                              _presetColorButton(
                                Colors.blue[300]!,
                                () => ref
                                    .read(colorPickerProvider.notifier)
                                    .setColor(Colors.blue[300]!),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Reset Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(colorPickerProvider.notifier)
                                .setColor(Colors.black);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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

  Widget _presetColorButton(Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: Colors.grey[600]!,
            width: 0.5,
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
  late Offset _selectedPosition;

  @override
  void initState() {
    super.initState();
    _selectedPosition = const Offset(0.8, 0.2);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) => _updateColor(details.localPosition),
      onPanUpdate: (details) => _updateColor(details.localPosition),
      child: CustomPaint(
        painter: HSVColorPickerPainter(hueValue: widget.hueValue),
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.grey[600]!,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Selection indicator
              Positioned(
                left: _selectedPosition.dx - 6,
                top: _selectedPosition.dy - 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
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

  void _updateColor(Offset position) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size size = box.size;

    final x = position.dx.clamp(0.0, size.width);
    final y = position.dy.clamp(0.0, 140.0);

    setState(() {
      _selectedPosition = Offset(x, y);
    });

    _notifyColorChange();
  }

  void _notifyColorChange() {
    final saturation = (_selectedPosition.dx / 256.0).clamp(0.0, 1.0);
    final value = (1.0 - (_selectedPosition.dy / 140.0)).clamp(0.0, 1.0);

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

    // Create the HSV color at full saturation and value
    final pureColor = HSVColor.fromAHSV(1, hueValue, 1, 1).toColor();

    // Create gradient: left to right for saturation (white to color)
    final saturationGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, pureColor],
    );

    // Paint saturation gradient
    final saturationPaint = Paint()
      ..shader = saturationGradient.createShader(rect);
    canvas.drawRect(rect, saturationPaint);

    // Create gradient: top to bottom for value/brightness (transparent to black)
    final brightnessGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    );

    // Paint brightness overlay
    final brightnessPaint = Paint()
      ..shader = brightnessGradient.createShader(rect);
    canvas.drawRect(rect, brightnessPaint);
  }

  @override
  bool shouldRepaint(HSVColorPickerPainter oldDelegate) {
    return oldDelegate.hueValue != hueValue;
  }
}
