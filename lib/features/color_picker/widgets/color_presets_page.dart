import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'color_preset_selector.dart';
import '../providers/color_picker_provider.dart';

class ColorPresetsPage extends ConsumerWidget {
  const ColorPresetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Presets'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              ColorPresetSelector(
                onPresetSelected: (colors) {
                  // Handle preset selection
                  if (colors.isNotEmpty) {
                    ref.read(colorPickerProvider.notifier).setColor(colors[0]);
                  }
                },
                onColorSelected: (color) {
                  ref.read(colorPickerProvider.notifier).setColor(color);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
