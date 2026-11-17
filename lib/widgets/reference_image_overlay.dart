import 'package:flutter/material.dart';

class ReferenceImageOverlay extends StatelessWidget {
  final String imagePath;
  final bool isVisible;

  const ReferenceImageOverlay({
    super.key,
    required this.imagePath,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

