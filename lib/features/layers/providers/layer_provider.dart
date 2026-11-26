import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/layer_model.dart';
import '../../../core/utils/uuid_generator.dart';

class LayerStackNotifier extends StateNotifier<LayerStack> {
  LayerStackNotifier() : super(_initialState());

  /// Callback to notify when a layer is deleted (for canvas cleanup)
  Function(String layerId)? onLayerDeleted;

  static LayerStack _initialState() {
    // Create background layer (locked by default)
    final bgLayer = Layer(
      id: UuidGenerator.generate(),
      name: 'Background',
      isLocked: true,
      type: 'basic',
    );

    // Create new layer for drawing
    final newLayer = Layer(
      id: UuidGenerator.generate(),
      name: 'New Layer',
      isLocked: false,
      type: 'basic',
    );

    return LayerStack(
      layers: [newLayer, bgLayer],
      activeLayerIndex: 0,
    );
  }

  /// Add a new basic layer
  void addBasicLayer(String name) {
    final newLayer = Layer(
      id: UuidGenerator.generate(),
      name: name,
      type: 'basic',
    );
    state = state.copyWith(
      layers: [newLayer, ...state.layers],
      activeLayerIndex: 0,
    );
  }

  /// Add a new group layer
  void addGroupLayer(String name) {
    final groupLayer = Layer(
      id: UuidGenerator.generate(),
      name: name,
      type: 'group',
      childLayerIds: [],
    );
    state = state.copyWith(
      layers: [groupLayer, ...state.layers],
      activeLayerIndex: 0,
    );
  }

  /// Delete a layer by index (smart deletion for groups - ungroups children)
  void deleteLayer(int index) {
    deleteLayerSmart(index);
  }

  /// Delete a layer by index (smart deletion for groups - ungroups children)
  void deleteLayerSmart(int index) {
    if (index < 0 || index >= state.layers.length) return;
    if (state.layers[index].name == 'Background') return;

    final layers = [...state.layers];
    final layerToDelete = layers[index];

    // If it's a group, ungroup its children
    if (layerToDelete.type == 'group') {
      final children = layerToDelete.childLayerIds;

      // Update all children to remove parent reference
      for (var childId in children) {
        for (int i = 0; i < layers.length; i++) {
          if (layers[i].id == childId) {
            layers[i] = layers[i].copyWith(parentId: null);
            break;
          }
        }
      }
    }

    // Notify drawing system
    onLayerDeleted?.call(layerToDelete.id);

    // Remove the layer
    layers.removeAt(index);

    if (layers.isEmpty) return;

    int newActiveIndex = state.activeLayerIndex;
    if (newActiveIndex >= layers.length) {
      newActiveIndex = layers.length - 1;
    }

    state = state.copyWith(
      layers: layers,
      activeLayerIndex: newActiveIndex,
    );
  }

  /// Select a layer
  void selectLayer(int index) {
    state = state.copyWith(activeLayerIndex: index);
  }

  /// Rename a layer
  void renameLayer(int index, String newName) {
    if (newName.isEmpty) return;
    final layers = [...state.layers];
    layers[index] = layers[index].copyWith(name: newName);
    state = state.copyWith(layers: layers);
  }

  /// Toggle layer visibility
  void toggleVisibility(int index) {
    final layers = [...state.layers];
    layers[index] = layers[index].copyWith(
      isVisible: !layers[index].isVisible,
    );
    state = state.copyWith(layers: layers);
  }

  /// Toggle layer lock (allow background to be unlocked, but locked by default)
  void toggleLock(int index) {
    final layers = [...state.layers];
    layers[index] = layers[index].copyWith(
      isLocked: !layers[index].isLocked,
    );
    state = state.copyWith(layers: layers);
  }

  /// Set layer opacity
  void setOpacity(int index, double opacity) {
    final layers = [...state.layers];
    layers[index] = layers[index].copyWith(opacity: opacity.clamp(0.0, 1.0));
    state = state.copyWith(layers: layers);
  }

  /// Move layer up (towards top of canvas)
  void moveLayerUp(int index) {
    if (index <= 0) return;

    final layers = [...state.layers];
    final temp = layers[index];
    layers[index] = layers[index - 1];
    layers[index - 1] = temp;

    // Update active layer index if it moved
    int newActiveIndex = state.activeLayerIndex;
    if (newActiveIndex == index) {
      newActiveIndex = index - 1;
    } else if (newActiveIndex == index - 1) {
      newActiveIndex = index;
    }

    state = state.copyWith(
      layers: layers,
      activeLayerIndex: newActiveIndex,
    );
  }

  /// Move layer down (towards bottom of canvas)
  void moveLayerDown(int index) {
    if (index >= state.layers.length - 1) return;

    final layers = [...state.layers];
    final temp = layers[index];
    layers[index] = layers[index + 1];
    layers[index + 1] = temp;

    // Update active layer index if it moved
    int newActiveIndex = state.activeLayerIndex;
    if (newActiveIndex == index) {
      newActiveIndex = index + 1;
    } else if (newActiveIndex == index + 1) {
      newActiveIndex = index;
    }

    state = state.copyWith(
      layers: layers,
      activeLayerIndex: newActiveIndex,
    );
  }

  /// Reorder layer by dragging (move from oldIndex to newIndex)
  void reorderLayer(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || oldIndex >= state.layers.length) return;
    if (newIndex < 0 || newIndex >= state.layers.length) return;

    final layers = [...state.layers];
    final layer = layers.removeAt(oldIndex);
    layers.insert(newIndex, layer);

    // Update active layer index
    int newActiveIndex = state.activeLayerIndex;
    if (newActiveIndex == oldIndex) {
      newActiveIndex = newIndex;
    } else if (oldIndex < newIndex &&
        newActiveIndex > oldIndex &&
        newActiveIndex <= newIndex) {
      newActiveIndex--;
    } else if (oldIndex > newIndex &&
        newActiveIndex >= newIndex &&
        newActiveIndex < oldIndex) {
      newActiveIndex++;
    }

    state = state.copyWith(
      layers: layers,
      activeLayerIndex: newActiveIndex,
    );
  }

  /// Add a layer to a group (nest layer inside group)
  void addLayerToGroup(int layerIndex, int groupIndex) {
    if (layerIndex == groupIndex) return;
    if (layerIndex < 0 || layerIndex >= state.layers.length) return;
    if (groupIndex < 0 || groupIndex >= state.layers.length) return;

    final groupLayer = state.layers[groupIndex];
    if (groupLayer.type != 'group') return; // Target must be a group

    final layers = [...state.layers];
    final layerToMove = layers[layerIndex];

    // Add to group's children
    final updatedGroupLayer = groupLayer.copyWith(
      childLayerIds: [...groupLayer.childLayerIds, layerToMove.id],
    );

    // Update layer with parent reference
    final updatedLayer = layerToMove.copyWith(parentId: groupLayer.id);

    layers[groupIndex] = updatedGroupLayer;
    layers[layerIndex] = updatedLayer;

    state = state.copyWith(layers: layers);
  }

  /// Remove a layer from its group
  void removeLayerFromGroup(int layerIndex) {
    if (layerIndex < 0 || layerIndex >= state.layers.length) return;

    final layers = [...state.layers];
    final layer = layers[layerIndex]; // Not in a group

    // Find parent group and remove from children
    int parentIndex = -1;
    for (int i = 0; i < layers.length; i++) {
      if (layers[i].id == layer.parentId) {
        parentIndex = i;
        break;
      }
    }

    if (parentIndex != -1) {
      final parentGroup = layers[parentIndex];
      final updatedParent = parentGroup.copyWith(
        childLayerIds:
            parentGroup.childLayerIds.where((id) => id != layer.id).toList(),
      );
      layers[parentIndex] = updatedParent;
    }

    // Remove parent reference
    layers[layerIndex] = layer.copyWith(parentId: null);

    state = state.copyWith(layers: layers);
  }

  /// Move a layer from one group to another group
  /// If the layer is currently in a group, it removes it from the old group first
  void moveLayerBetweenGroups(int layerIndex, int targetGroupIndex) {
    if (layerIndex == targetGroupIndex) return;
    if (layerIndex < 0 || layerIndex >= state.layers.length) return;
    if (targetGroupIndex < 0 || targetGroupIndex >= state.layers.length) return;

    final targetGroup = state.layers[targetGroupIndex];
    if (targetGroup.type != 'group') return; // Target must be a group

    final layers = [...state.layers];
    final layerToMove = layers[layerIndex];

    // If layer is currently in a group, remove it from that group first
    if (layerToMove.parentId != null && layerToMove.parentId!.isNotEmpty) {
      int oldParentIndex = -1;
      for (int i = 0; i < layers.length; i++) {
        if (layers[i].id == layerToMove.parentId) {
          oldParentIndex = i;
          break;
        }
      }

      if (oldParentIndex != -1) {
        final oldParentGroup = layers[oldParentIndex];
        final updatedOldParent = oldParentGroup.copyWith(
          childLayerIds: oldParentGroup.childLayerIds
              .where((id) => id != layerToMove.id)
              .toList(),
        );
        layers[oldParentIndex] = updatedOldParent;
      }
    }

    // Add to new group's children
    final updatedTargetGroup = targetGroup.copyWith(
      childLayerIds: [...targetGroup.childLayerIds, layerToMove.id],
    );

    // Update layer with new parent reference
    final updatedLayer = layerToMove.copyWith(parentId: targetGroup.id);

    layers[targetGroupIndex] = updatedTargetGroup;
    layers[layerIndex] = updatedLayer;

    state = state.copyWith(layers: layers);
  }

  /// Set blend mode for a layer
  void setBlendMode(int index, BlendMode blendMode) {
    if (index < 0 || index >= state.layers.length) return;

    final layers = [...state.layers];
    layers[index] = layers[index].copyWith(blendMode: blendMode);
    state = state.copyWith(layers: layers);
  }
}

final layerStackProvider =
    StateNotifierProvider<LayerStackNotifier, LayerStack>((ref) {
  return LayerStackNotifier();
});
