import 'package:material_ui/material_ui.dart';
import '../models/brush_model.dart';

class BrushPreviewPainter extends CustomPainter {
  final Brush brush;

  BrushPreviewPainter({required this.brush});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.grey[600]!.withAlpha(150)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    switch (brush.type) {
      case 'sketching':
        _drawSketchingStroke(canvas, centerX, centerY, paint, fillPaint);
        break;
      case 'painting':
        _drawPaintingStroke(canvas, centerX, centerY, paint, fillPaint);
        break;
      case 'ink':
        _drawInkStroke(canvas, centerX, centerY, paint, fillPaint);
        break;
      case 'watercolor':
        _drawWatercolorStroke(canvas, centerX, centerY, paint, fillPaint);
        break;
      case 'charcoal':
        _drawCharcoalStroke(canvas, centerX, centerY, paint, fillPaint);
        break;
      case 'chalk':
        _drawChalkStroke(canvas, centerX, centerY, paint, fillPaint);
        break;
      case 'airbrush':
        _drawAirbrushStroke(canvas, centerX, centerY, paint, fillPaint);
        break;
      case 'texture':
        _drawTextureStroke(canvas, centerX, centerY, paint, fillPaint);
        break;
      default:
        _drawDefaultStroke(canvas, centerX, centerY, paint, fillPaint);
    }
  }

  void _drawSketchingStroke(
    Canvas canvas,
    double centerX,
    double centerY,
    Paint outlinePaint,
    Paint fillPaint,
  ) {
    // Thin lines for sketching
    for (int i = 0; i < 3; i++) {
      final offset = i * 2.0 - 2.0;
      canvas.drawLine(
        Offset(centerX - 20, centerY + offset),
        Offset(centerX + 20, centerY + offset),
        outlinePaint..strokeWidth = 1.0,
      );
    }
  }

  void _drawPaintingStroke(
    Canvas canvas,
    double centerX,
    double centerY,
    Paint outlinePaint,
    Paint fillPaint,
  ) {
    // Soft round brush
    final path = Path();
    path.moveTo(centerX - 25, centerY);
    path.cubicTo(
      centerX - 25,
      centerY - 15,
      centerX + 25,
      centerY - 15,
      centerX + 25,
      centerY,
    );
    path.cubicTo(
      centerX + 25,
      centerY + 15,
      centerX - 25,
      centerY + 15,
      centerX - 25,
      centerY,
    );
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, outlinePaint);
  }

  void _drawInkStroke(
    Canvas canvas,
    double centerX,
    double centerY,
    Paint outlinePaint,
    Paint fillPaint,
  ) {
    // Sharp, precise line
    final strokePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX - 20, centerY + 10),
      Offset(centerX + 20, centerY - 10),
      strokePaint,
    );
  }

  void _drawWatercolorStroke(
    Canvas canvas,
    double centerX,
    double centerY,
    Paint outlinePaint,
    Paint fillPaint,
  ) {
    // Soft, irregular edges
    final waterPaint = Paint()
      ..color = Colors.blue.withAlpha(100)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX - 8, centerY), 12, waterPaint);
    canvas.drawCircle(Offset(centerX + 8, centerY), 12, waterPaint);
    canvas.drawCircle(Offset(centerX, centerY + 5), 15, waterPaint);
  }

  void _drawCharcoalStroke(
    Canvas canvas,
    double centerX,
    double centerY,
    Paint outlinePaint,
    Paint fillPaint,
  ) {
    // Rough, textured appearance
    final charcoalPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final x = centerX - 20 + (i * 5);
      final y = centerY + (i % 2 == 0 ? -3 : 3);
      canvas.drawCircle(Offset(x, y), 3, charcoalPaint);
    }
  }

  void _drawChalkStroke(
    Canvas canvas,
    double centerX,
    double centerY,
    Paint outlinePaint,
    Paint fillPaint,
  ) {
    // Pastel-like appearance
    final chalkPaint = Paint()
      ..color = Colors.amber[200]!
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: 40,
          height: 12,
        ),
        const Radius.circular(6),
      ),
      chalkPaint,
    );
  }

  void _drawAirbrushStroke(
    Canvas canvas,
    double centerX,
    double centerY,
    Paint outlinePaint,
    Paint fillPaint,
  ) {
    // Soft spray gradient
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.grey[600]!.withAlpha(200),
          Colors.grey[600]!.withAlpha(80),
        ],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: 20));
    canvas.drawCircle(Offset(centerX, centerY), 20, gradientPaint);
  }

  void _drawTextureStroke(
    Canvas canvas,
    double centerX,
    double centerY,
    Paint outlinePaint,
    Paint fillPaint,
  ) {
    // Pattern texture
    final texturePaint = Paint()
      ..color = Colors.grey[500]!
      ..style = PaintingStyle.fill;
    for (int x = -15; x <= 15; x += 3) {
      for (int y = -8; y <= 8; y += 3) {
        canvas.drawRect(
          Rect.fromLTWH(centerX + x, centerY + y, 2, 2),
          texturePaint,
        );
      }
    }
  }

  void _drawDefaultStroke(
    Canvas canvas,
    double centerX,
    double centerY,
    Paint outlinePaint,
    Paint fillPaint,
  ) {
    canvas.drawCircle(Offset(centerX, centerY), 15, fillPaint);
    canvas.drawCircle(Offset(centerX, centerY), 15, outlinePaint);
  }

  @override
  bool shouldRepaint(BrushPreviewPainter oldDelegate) =>
      oldDelegate.brush.id != brush.id;
}
