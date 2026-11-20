import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class ColorPickerState {
  final Color selectedColor;
  final double hue;
  final double saturation;
  final double value;
  final List<Color> generatedPresets;
  final List<Color> usedColors;
  final Map<String, List<Color>> customPalettes;
  final bool presetsExpanded;

  ColorPickerState({
    this.selectedColor = const Color(0xFF000000),
    this.hue = 0.0,
    this.saturation = 0.0,
    this.value = 0.0,
    this.generatedPresets = const [],
    this.usedColors = const [],
    this.customPalettes = const {},
    this.presetsExpanded = true,
  });

  ColorPickerState copyWith({
    Color? selectedColor,
    double? hue,
    double? saturation,
    double? value,
    List<Color>? generatedPresets,
    List<Color>? usedColors,
    Map<String, List<Color>>? customPalettes,
    bool? presetsExpanded,
  }) {
    return ColorPickerState(
      selectedColor: selectedColor ?? this.selectedColor,
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      value: value ?? this.value,
      generatedPresets: generatedPresets ?? this.generatedPresets,
      usedColors: usedColors ?? this.usedColors,
      customPalettes: customPalettes ?? this.customPalettes,
      presetsExpanded: presetsExpanded ?? this.presetsExpanded,
    );
  }
}

class ColorPickerNotifier extends StateNotifier<ColorPickerState> {
  ColorPickerNotifier() : super(ColorPickerState());

  /// Update color using HSV values (for color picker selection, NOT canvas use)
  void setColorFromHSV(double hue, double saturation, double value) {
    final color = HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
    state = state.copyWith(
      selectedColor: color,
      hue: hue,
      saturation: saturation,
      value: value,
    );
    _generateColorPresets(hue);
  }

  /// Update hue only
  void setHue(double hue) {
    setColorFromHSV(hue, state.saturation, state.value);
  }

  /// Update saturation only
  void setSaturation(double saturation) {
    setColorFromHSV(state.hue, saturation, state.value);
  }

  /// Update value only
  void setValue(double value) {
    setColorFromHSV(state.hue, state.saturation, value);
  }

  /// Set color directly (for color picker selection, NOT canvas use)
  void setColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    state = state.copyWith(
      selectedColor: color,
      hue: hsv.hue,
      saturation: hsv.saturation,
      value: hsv.value,
    );
    _generateColorPresets(hsv.hue);
  }

  /// Generate 16 color presets based on current hue
  void _generateColorPresets(double hue) {
    final presets = <Color>[];
    for (int i = 0; i < 16; i++) {
      // Create colors with different saturation and value combinations
      final saturation = (i % 4 + 1) / 4; // 0.25, 0.5, 0.75, 1.0
      final value = (i ~/ 4 + 1) / 4; // 0.25, 0.5, 0.75, 1.0
      final color = HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
      presets.add(color);
    }
    state = state.copyWith(generatedPresets: presets);
  }

  /// Add color to used colors history (keep last 40)
  void _addToUsedColors(Color color) {
    final colors = <Color>[color];
    for (final c in state.usedColors) {
      if (c.toARGB32() != color.toARGB32() && colors.length < 40) {
        colors.add(c);
      }
    }
    state = state.copyWith(usedColors: colors);
  }

  /// Track color when used on canvas (call this when user draws)
  void trackColorUsedOnCanvas(Color color) {
    _addToUsedColors(color);
  }

  /// Toggle presets expansion
  void togglePresetsExpanded() {
    state = state.copyWith(presetsExpanded: !state.presetsExpanded);
  }

  /// Add custom palette
  void addCustomPalette(String name, List<Color> colors) {
    final palettes = Map<String, List<Color>>.from(state.customPalettes);
    palettes[name] = colors;
    state = state.copyWith(customPalettes: palettes);
  }

  /// Remove custom palette
  void removeCustomPalette(String name) {
    final palettes = Map<String, List<Color>>.from(state.customPalettes);
    palettes.remove(name);
    state = state.copyWith(customPalettes: palettes);
  }

  /// Add current color to custom palette
  void addColorToCustomPalette(String paletteName, Color color) {
    final palettes = Map<String, List<Color>>.from(state.customPalettes);
    final palette = palettes[paletteName] ?? [];
    if (!palette.contains(color)) {
      palette.add(color);
      palettes[paletteName] = palette;
      state = state.copyWith(customPalettes: palettes);
    }
  }

  /// Reset to default black color
  void resetColor() {
    state = ColorPickerState();
  }
}

final colorPickerProvider =
    StateNotifierProvider<ColorPickerNotifier, ColorPickerState>((ref) {
  return ColorPickerNotifier();
});

final colorPickerOpenProvider = StateProvider<bool>((ref) => false);

// New provider to track palette display mode
final paletteDisplayModeProvider = StateProvider<String>((ref) => 'normal');
