import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drawing_models.dart';
import '../notifiers/drawing_notifier.dart';

final drawingNotifierProvider =
    StateNotifierProvider<DrawingNotifier, DrawingState>((ref) {
  return DrawingNotifier();
});
