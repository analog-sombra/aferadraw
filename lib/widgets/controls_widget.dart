import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../notifiers/enhanced_drawing_notifier.dart';
import '../models/drawing_models.dart';

class ControlsWidget extends ConsumerWidget {
  const ControlsWidget({super.key});

  Future<void> _pickReferenceImage(WidgetRef ref) async {
    final notifier = ref.read(enhancedDrawingNotifierProvider.notifier);
    final picker = ImagePicker();
    
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        notifier.addReferenceImage(ReferenceImage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imagePath: pickedFile.path,
        ));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingProvider = ref.watch(enhancedDrawingNotifierProvider);
    final notifier = ref.read(enhancedDrawingNotifierProvider.notifier);
    final hasImages = drawingProvider.referenceImages.isNotEmpty;
    final currentImage = drawingProvider.currentRefImage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onDoubleTap: () {
              notifier.resetZoom();
            },
            onVerticalDragUpdate: (details) {
              notifier.updateZoom(details.delta.dy);
            },
            child: Column(
              children: [
                const Icon(Icons.zoom_in, size: 24, color: Colors.blue),
                Text(
                  '${(drawingProvider.scale * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ),
          ),
          GestureDetector(
            onDoubleTap: () {
              notifier.resetRotation();
            },
            onVerticalDragUpdate: (details) {
              notifier.updateRotation(details.delta.dy);
            },
            child: Column(
              children: [
                const Icon(Icons.rotate_right, size: 24, color: Colors.green),
                Text(
                  '${(drawingProvider.rotation * 180 / 3.14159).toStringAsFixed(0)}°',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ),
          GestureDetector(
            onDoubleTap: () {
              notifier.resetScale();
            },
            onVerticalDragUpdate: (details) {
              notifier.updateScale(details.delta.dy);
            },
            child: Column(
              children: [
                const Icon(Icons.aspect_ratio, size: 24, color: Colors.orange),
                Text(
                  '${drawingProvider.scale.toStringAsFixed(2)}x',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
          ),
          GestureDetector(
            onDoubleTap: () {
              notifier.resetAll();
            },
            child: Column(
              children: [
                const Icon(Icons.pan_tool, size: 24, color: Colors.red),
                Text(
                  'X:${drawingProvider.offsetX.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
                Text(
                  'Y:${drawingProvider.offsetY.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
              ],
            ),
          ),
          if (!hasImages)
            GestureDetector(
              onTap: () => _pickReferenceImage(ref),
              child: const Column(
                children: [
                  Icon(Icons.add_a_photo, size: 24, color: Colors.purple),
                  Text(
                    'Ref',
                    style: TextStyle(fontSize: 12, color: Colors.purple),
                  ),
                ],
              ),
            )
          else if (currentImage != null)
            GestureDetector(
              onTap: () {
                if (drawingProvider.isShowingReferenceImage) {
                  notifier.hideReferenceImage();
                } else {
                  notifier.showReferenceImage();
                }
              },
              onLongPress: () => _pickReferenceImage(ref),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: drawingProvider.isShowingReferenceImage
                            ? Colors.purple
                            : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: drawingProvider.isShowingReferenceImage
                          ? Colors.purple.shade100
                          : Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(currentImage.imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Ref',
                        style: TextStyle(fontSize: 12, color: Colors.purple),
                      ),
                      if (drawingProvider.referenceImages.length > 1)
                        Text(
                          '${drawingProvider.currentRefImageIndex + 1}/${drawingProvider.referenceImages.length}',
                          style: const TextStyle(fontSize: 10, color: Colors.purple),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

