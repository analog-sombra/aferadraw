import 'package:material_ui/material_ui.dart';
import '../models/brush_model.dart';

class BrushPreviewPainter extends CustomPainter {
  final Brush brush;

  BrushPreviewPainter({required this.brush});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Simple brush preview - thin lines
    for (int i = 0; i < 3; i++) {
      final offset = i * 2.0 - 2.0;
      canvas.drawLine(
        Offset(centerX - 20, centerY + offset),
        Offset(centerX + 20, centerY + offset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BrushPreviewPainter oldDelegate) =>
      oldDelegate.brush.id != brush.id;
}
