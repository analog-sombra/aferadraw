import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Represents a palette (can be local or AI)
class Palette {
  final String name;
  final List<Color> colors;
  final bool isAI; // true if from AI, false if local preset

  Palette({
    required this.name,
    required this.colors,
    this.isAI = false,
  });

  Palette copyWith({
    String? name,
    List<Color>? colors,
    bool? isAI,
  }) {
    return Palette(
      name: name ?? this.name,
      colors: colors ?? this.colors,
      isAI: isAI ?? this.isAI,
    );
  }
}

/// Simple state for palette selection
class PaletteState {
  final Palette? selectedPalette;

  PaletteState({this.selectedPalette});

  PaletteState copyWith({Palette? selectedPalette}) {
    return PaletteState(
      selectedPalette: selectedPalette ?? this.selectedPalette,
    );
  }
}

class PaletteNotifier extends StateNotifier<PaletteState> {
  PaletteNotifier() : super(PaletteState(selectedPalette: null));

  /// Set a palette as selected
  void selectPalette(String name, List<Color> colors, {bool isAI = false}) {
    print(
        '[DEBUG PaletteNotifier] selectPalette: name=$name, colorCount=${colors.length}, isAI=$isAI');
    state = state.copyWith(
      selectedPalette: Palette(
        name: name,
        colors: colors,
        isAI: isAI,
      ),
    );
  }

  /// Clear selected palette
  void clearPalette() {
    print('[DEBUG PaletteNotifier] clearPalette');
    state = PaletteState(selectedPalette: null);
  }
}

final paletteStateProvider =
    StateNotifierProvider<PaletteNotifier, PaletteState>((ref) {
  return PaletteNotifier();
});
