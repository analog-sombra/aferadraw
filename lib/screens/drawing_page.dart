import 'package:flutter/material.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/canvas_widget.dart';
import '../widgets/controls_widget.dart';

class DrawingPage extends StatelessWidget {
  const DrawingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ToolbarWidget(),
            const CanvasWidget(),
            const ControlsWidget(),
          ],
        ),
      ),
    );
  }
}
