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
            flow: 1.0,
            stabilizer: 0.3,
          ),
        );

  void updateSize(double size) {
    state = state.copyWith(defaultSize: size);
  }

  void updateOpacity(double opacity) {
    state = state.copyWith(defaultOpacity: opacity);
  }

  void updateHardness(double hardness) {
    state = state.copyWith(hardness: hardness);
  }

  void updateFlow(double flow) {
    state = state.copyWith(flow: flow);
  }

  void updateStabilizer(double stabilizer) {
    state = state.copyWith(stabilizer: stabilizer);
  }
}

final availableBrushesProvider = Provider<List<Brush>>((ref) {
  return [
    Brush(
      id: 'default_brush',
      name: 'Default Brush',
      type: 'sketching',
      defaultSize: 10.0,
      defaultOpacity: 1.0,
      hardness: 0.8,
      flow: 1.0,
      stabilizer: 0.3,
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
