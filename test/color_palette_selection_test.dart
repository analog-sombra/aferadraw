import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aferadraw/features/color_picker/providers/color_picker_provider.dart';

void main() {
  group('Color Palette Selection', () {
    test('addCustomPalette sets selectedPaletteName', () {
      final container = ProviderContainer();
      final notifier = container.read(colorPickerProvider.notifier);
      
      final colors = [Colors.red, Colors.green, Colors.blue];
      notifier.addCustomPalette('Test Palette', colors);
      
      final state = container.read(colorPickerProvider);
      
      expect(state.selectedPaletteName, equals('Test Palette'));
      expect(state.customPalettes.containsKey('Test Palette'), isTrue);
      expect(state.customPalettes['Test Palette'], equals(colors));
    });

    test('setSelectedPalette updates selectedPaletteName', () {
      final container = ProviderContainer();
      final notifier = container.read(colorPickerProvider.notifier);
      
      final colors1 = [Colors.red, Colors.green];
      final colors2 = [Colors.blue, Colors.yellow];
      
      notifier.addCustomPalette('Palette 1', colors1);
      notifier.addCustomPalette('Palette 2', colors2);
      
      var state = container.read(colorPickerProvider);
      expect(state.selectedPaletteName, equals('Palette 2'));
      
      notifier.setSelectedPalette('Palette 1');
      state = container.read(colorPickerProvider);
      
      expect(state.selectedPaletteName, equals('Palette 1'));
    });

    test('removeCustomPalette updates selectedPaletteName when selected palette is deleted', () {
      final container = ProviderContainer();
      final notifier = container.read(colorPickerProvider.notifier);
      
      final colors1 = [Colors.red];
      final colors2 = [Colors.blue];
      
      notifier.addCustomPalette('Palette 1', colors1);
      notifier.addCustomPalette('Palette 2', colors2);
      
      var state = container.read(colorPickerProvider);
      expect(state.selectedPaletteName, equals('Palette 2'));
      
      notifier.removeCustomPalette('Palette 2');
      state = container.read(colorPickerProvider);
      
      expect(state.selectedPaletteName, equals('Palette 1'));
      expect(state.customPalettes.containsKey('Palette 2'), isFalse);
    });

    test('removeCustomPalette sets selectedPaletteName to null when all palettes removed', () {
      final container = ProviderContainer();
      final notifier = container.read(colorPickerProvider.notifier);
      
      final colors = [Colors.red, Colors.green];
      notifier.addCustomPalette('Only Palette', colors);
      
      notifier.removeCustomPalette('Only Palette');
      final state = container.read(colorPickerProvider);
      
      expect(state.selectedPaletteName, isNull);
      expect(state.customPalettes.isEmpty, isTrue);
    });

    test('selectedPaletteName persists across color changes', () {
      final container = ProviderContainer();
      final notifier = container.read(colorPickerProvider.notifier);
      
      final colors = [Colors.red, Colors.green, Colors.blue];
      notifier.addCustomPalette('AI Palette', colors);
      
      notifier.setColor(Colors.purple);
      
      final state = container.read(colorPickerProvider);
      expect(state.selectedPaletteName, equals('AI Palette'));
      expect(state.selectedColor, equals(Colors.purple));
    });
  });
}
