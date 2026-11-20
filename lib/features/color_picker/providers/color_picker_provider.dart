import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class ColorPickerState {
  final Color selectedColor;
  final double hue;
  final double saturation;
  final double value;

  ColorPickerState({
    this.selectedColor = const Color(0xFF000000),
    this.hue = 0.0,
    this.saturation = 0.0,
    this.value = 0.0,
  });

  ColorPickerState copyWith({
    Color? selectedColor,
    double? hue,
    double? saturation,
    double? value,
  }) {
    return ColorPickerState(
      selectedColor: selectedColor ?? this.selectedColor,
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      value: value ?? this.value,
    );
  }
}

class ColorPickerNotifier extends StateNotifier<ColorPickerState> {
  ColorPickerNotifier() : super(ColorPickerState());

  /// Update color using HSV values
  void setColorFromHSV(double hue, double saturation, double value) {
    final color = HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
    state = state.copyWith(
      selectedColor: color,
      hue: hue,
      saturation: saturation,
      value: value,
    );
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

  /// Set color directly
  void setColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    state = state.copyWith(
      selectedColor: color,
      hue: hsv.hue,
      saturation: hsv.saturation,
      value: hsv.value,
    );
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
