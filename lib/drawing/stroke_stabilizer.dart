import 'dart:math' show max;
import 'package:flutter/rendering.dart';

/// Professional brush stabilizer using lazy rope + weighted moving average
/// Similar to Krita / Clip Studio Paint stabilization
class StrokeStabilizer {
  final double strength; // 0.0 (no stabilizer) to 1.0 (max stabilizer)
  final double canvasScale; // Current zoom level (1.0 = 100%)

  // Lazy rope anchor and state
  late Offset _anchor;
  late Offset _lastRawPoint;
  
  // Weighted moving average window
  final List<Offset> _anchorWindow = [];

  StrokeStabilizer({
    required this.strength,
    required this.canvasScale,
  });

  /// Reset stabilizer state at the start of a stroke
  Offset start(Offset p) {
    _anchor = p;
    _lastRawPoint = p;
    _anchorWindow.clear();
    _anchorWindow.add(p);
    return p;
  }

  /// Add a raw point and return stabilized point (or null if still within rope radius)
  Offset? add(Offset raw) {
    // If strength is 0, return raw point unchanged
    if (strength <= 0.0) {
      _lastRawPoint = raw;
      return raw;
    }

    _lastRawPoint = raw;

    // Calculate rope radius: (strength/100 * 40) / canvasScale
    // Clamp strength to [0, 1] range (it should already be, but just in case)
    final clampedStrength = strength.clamp(0.0, 1.0);
    final ropeRadius = (clampedStrength * 40.0) / max(0.1, canvasScale);

    // Distance from anchor to raw point
    final diff = raw - _anchor;
    final distance = diff.distance;

    // If within rope radius, return null (no output yet)
    if (distance <= ropeRadius) {
      return null;
    }

    // Move anchor toward raw by (distance - radius)
    // new_anchor = anchor + (raw - anchor) / distance * (distance - radius)
    final moveDistance = distance - ropeRadius;
    final direction = diff / distance;
    _anchor = _anchor + (direction * moveDistance);

    // Build weighted moving average window
    // N = 1 + round(strength * 11), so N ranges from 1 to 12
    final windowSize = 1 + (clampedStrength * 11.0).round();

    _anchorWindow.add(_anchor);
    if (_anchorWindow.length > windowSize) {
      _anchorWindow.removeAt(0);
    }

    // Weighted average with linearly increasing weights
    // Newest point weighs most: last point has weight N, first has weight 1
    double totalWeight = 0.0;
    double avgX = 0.0;
    double avgY = 0.0;

    final len = _anchorWindow.length;
    for (int i = 0; i < len; i++) {
      final weight = (i + 1).toDouble(); // 1, 2, 3, ..., N
      final point = _anchorWindow[i];
      avgX += point.dx * weight;
      avgY += point.dy * weight;
      totalWeight += weight;
    }

    final smoothedPoint = Offset(avgX / totalWeight, avgY / totalWeight);
    return smoothedPoint;
  }

  /// Finish stroke: return interpolated points from last smoothed to last raw, spaced ~2px
  List<Offset> finish() {
    if (_anchorWindow.isEmpty) return [];

    final lastSmoothed = _anchorWindow.last;
    final lastRaw = _lastRawPoint;

    final diff = lastRaw - lastSmoothed;
    final distance = diff.distance;

    if (distance <= 0.1) {
      return [];
    }

    // Interpolate every ~2px
    final steps = max(2, (distance / 2.0).ceil());
    final interpolated = <Offset>[];

    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final point = Offset(
        lastSmoothed.dx + diff.dx * t,
        lastSmoothed.dy + diff.dy * t,
      );
      interpolated.add(point);
    }

    // Add the final raw point
    interpolated.add(lastRaw);

    return interpolated;
  }
}
