import 'package:flutter/material.dart';

class ColorPreset {
  final String name;
  final List<Color> colors;
  final String description;

  ColorPreset({
    required this.name,
    required this.colors,
    this.description = '',
  });

  factory ColorPreset.fromHexList(String name, List<String> hexColors, {String description = ''}) {
    final colors = hexColors.map((hex) => _hexToColor(hex)).toList();
    return ColorPreset(
      name: name,
      colors: colors,
      description: description,
    );
  }

  static Color _hexToColor(String hexString) {
    hexString = hexString.replaceFirst('#', '');
    if (hexString.length == 6) {
      hexString = 'FF$hexString';
    }
    return Color(int.parse(hexString, radix: 16));
  }
}
