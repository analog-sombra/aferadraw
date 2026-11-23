import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brush_model.dart';

final brushPanelOpenProvider = StateProvider<bool>((ref) => false);

final brushProvider = StateNotifierProvider<BrushNotifier, Brush>((ref) {
  return BrushNotifier();
});

class BrushNotifier extends StateNotifier<Brush> {
  BrushNotifier()
      : super(
          Brush(
            id: 'default_brush',
            name: 'Default Brush',
            type: 'sketching',
            defaultSize: 10.0,
            defaultOpacity: 1.0,
            hardness: 0.8,
          ),
        );

  void selectBrush(Brush brush) {
    state = brush;
  }

  void updateSize(double size) {
    state = state.copyWith(defaultSize: size);
  }

  void updateOpacity(double opacity) {
    state = state.copyWith(defaultOpacity: opacity);
  }

  void updateHardness(double hardness) {
    state = state.copyWith(hardness: hardness);
  }
}

final availableBrushesProvider = Provider<List<Brush>>((ref) {
  return [
    Brush(
      id: 'sketch_1',
      name: 'Sketching Pencil',
      type: 'sketching',
      defaultSize: 5.0,
      hardness: 0.95,
    ),
    Brush(
      id: 'sketch_2',
      name: 'Sketching Pen',
      type: 'sketching',
      defaultSize: 3.0,
      hardness: 1.0,
    ),
    Brush(
      id: 'paint_1',
      name: 'Round Brush',
      type: 'painting',
      defaultSize: 15.0,
      hardness: 0.7,
    ),
    Brush(
      id: 'paint_2',
      name: 'Soft Round',
      type: 'painting',
      defaultSize: 20.0,
      hardness: 0.3,
    ),
    Brush(
      id: 'ink_1',
      name: 'Ink Pen',
      type: 'ink',
      defaultSize: 2.0,
      hardness: 1.0,
    ),
    Brush(
      id: 'ink_2',
      name: 'Ink Brush',
      type: 'ink',
      defaultSize: 12.0,
      hardness: 0.9,
    ),
    Brush(
      id: 'water_1',
      name: 'Watercolor Light',
      type: 'watercolor',
      defaultSize: 25.0,
      hardness: 0.2,
      defaultOpacity: 0.6,
    ),
    Brush(
      id: 'water_2',
      name: 'Watercolor Medium',
      type: 'watercolor',
      defaultSize: 20.0,
      hardness: 0.3,
      defaultOpacity: 0.8,
    ),
    Brush(
      id: 'charcoal_1',
      name: 'Charcoal',
      type: 'charcoal',
      defaultSize: 18.0,
      hardness: 0.4,
    ),
    Brush(
      id: 'chalk_1',
      name: 'Chalk',
      type: 'chalk',
      defaultSize: 16.0,
      hardness: 0.5,
    ),
    Brush(
      id: 'air_1',
      name: 'Airbrush Soft',
      type: 'airbrush',
      defaultSize: 30.0,
      hardness: 0.1,
      defaultOpacity: 0.4,
    ),
    Brush(
      id: 'texture_1',
      name: 'Texture Brush',
      type: 'texture',
      defaultSize: 22.0,
      hardness: 0.6,
    ),
  ];
});

final brushesByTypeProvider = Provider<Map<String, List<Brush>>>((ref) {
  final allBrushes = ref.watch(availableBrushesProvider);
  final grouped = <String, List<Brush>>{};

  for (final brush in allBrushes) {
    grouped.putIfAbsent(brush.type, () => []).add(brush);
  }

  return grouped;
});
