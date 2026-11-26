class Brush {
  final String id;
  final String name;
  final String type; // 'sketching', 'painting', 'ink', 'watercolor', 'charcoal', 'chalk', 'airbrush', 'texture'
  final double defaultSize;
  final double defaultOpacity;
  final double hardness;
  final double flow;
  final double stabilizer; // 0.0 (no stabilizer) to 1.0 (max stabilizer)

  Brush({
    required this.id,
    required this.name,
    required this.type,
    this.defaultSize = 10.0,
    this.defaultOpacity = 1.0,
    this.hardness = 0.8,
    this.flow = 1.0,
    this.stabilizer = 0.0,
  });

  Brush copyWith({
    String? id,
    String? name,
    String? type,
    double? defaultSize,
    double? defaultOpacity,
    double? hardness,
    double? flow,
    double? stabilizer,
  }) {
    return Brush(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      defaultSize: defaultSize ?? this.defaultSize,
      defaultOpacity: defaultOpacity ?? this.defaultOpacity,
      hardness: hardness ?? this.hardness,
      flow: flow ?? this.flow,
      stabilizer: stabilizer ?? this.stabilizer,
    );
  }
}
