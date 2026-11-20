import 'package:flutter_test/flutter_test.dart';
import 'package:aferadraw/features/layers/models/layer_model.dart';
import 'package:aferadraw/features/layers/providers/layer_provider.dart';
import 'package:aferadraw/core/utils/uuid_generator.dart';

void main() {
  group('Layer Ungrouping', () {
    test('removeLayerFromGroup - removes layer from parent group', () {
      // Setup: Create a parent group and a child layer
      final parentId = UuidGenerator.generate();
      final childId = UuidGenerator.generate();
      
      final parentGroup = Layer(
        id: parentId,
        name: 'Parent Group',
        type: 'group',
        childLayerIds: [childId],
      );
      
      final childLayer = Layer(
        id: childId,
        name: 'Child Layer',
        type: 'basic',
        parentId: parentId,
      );
      
      final initialState = LayerStack(
        layers: [parentGroup, childLayer],
        activeLayerIndex: 1,
      );
      
      // Create notifier and set initial state
      final notifier = LayerStackNotifier();
      notifier.state = initialState;
      
      // Act: Remove child layer from parent group
      notifier.removeLayerFromGroup(1); // Index of child layer
      
      // Assert
      expect(notifier.state.layers.length, 2);
      
      // Child layer should have no parent
      final updatedChild = notifier.state.layers[1];
      expect(updatedChild.parentId, isNull);
      
      // Parent group should have empty childLayerIds
      final updatedParent = notifier.state.layers[0];
      expect(updatedParent.childLayerIds.isEmpty, isTrue);
    });

    test('removeLayerFromGroup - handles grouped layer inside group', () {
      // Setup: Create nested groups (Group1 contains Group2)
      final group1Id = UuidGenerator.generate();
      final group2Id = UuidGenerator.generate();
      
      final group1 = Layer(
        id: group1Id,
        name: 'Group1',
        type: 'group',
        childLayerIds: [group2Id],
      );
      
      final group2 = Layer(
        id: group2Id,
        name: 'Group2',
        type: 'group',
        childLayerIds: [],
        parentId: group1Id,
      );
      
      final initialState = LayerStack(
        layers: [group1, group2],
        activeLayerIndex: 1,
      );
      
      final notifier = LayerStackNotifier();
      notifier.state = initialState;
      
      // Act: Remove Group2 from Group1
      notifier.removeLayerFromGroup(1);
      
      // Assert
      final updatedGroup2 = notifier.state.layers[1];
      expect(updatedGroup2.parentId, isNull);
      
      final updatedGroup1 = notifier.state.layers[0];
      expect(updatedGroup1.childLayerIds.isEmpty, isTrue);
    });

    test('LayerDragData carries parent status correctly', () {
      // This test verifies that the LayerDragData class would correctly
      // identify grouped vs ungrouped layers
      
      final parentId = UuidGenerator.generate();
      final groupedLayer = Layer(
        id: UuidGenerator.generate(),
        name: 'Grouped',
        parentId: parentId,
      );
      
      final ungroupedLayer = Layer(
        id: UuidGenerator.generate(),
        name: 'Ungrouped',
      );
      
      // Simulate LayerDragData logic
      final groupedIsGrouped = groupedLayer.parentId != null && 
                               groupedLayer.parentId!.isNotEmpty;
      final ungroupedIsGrouped = ungroupedLayer.parentId != null && 
                                 ungroupedLayer.parentId!.isNotEmpty;
      
      expect(groupedIsGrouped, isTrue);
      expect(ungroupedIsGrouped, isFalse);
    });

    test('moveLayerBetweenGroups - moves layer from one group to another', () {
      // Setup: Create two groups and a layer in group1
      final group1Id = UuidGenerator.generate();
      final group2Id = UuidGenerator.generate();
      final layerId = UuidGenerator.generate();
      
      final group1 = Layer(
        id: group1Id,
        name: 'Group1',
        type: 'group',
        childLayerIds: [layerId],
      );
      
      final group2 = Layer(
        id: group2Id,
        name: 'Group2',
        type: 'group',
        childLayerIds: [],
      );
      
      final layer = Layer(
        id: layerId,
        name: 'Layer',
        parentId: group1Id,
      );
      
      final initialState = LayerStack(
        layers: [group1, group2, layer],
        activeLayerIndex: 2,
      );
      
      final notifier = LayerStackNotifier();
      notifier.state = initialState;
      
      // Act: Move layer from group1 to group2
      notifier.moveLayerBetweenGroups(2, 1); // Move layer (index 2) to group2 (index 1)
      
      // Assert
      final updatedGroup1 = notifier.state.layers[0];
      final updatedGroup2 = notifier.state.layers[1];
      final updatedLayer = notifier.state.layers[2];
      
      // Layer should be in group2 now
      expect(updatedLayer.parentId, group2Id);
      expect(updatedGroup1.childLayerIds.isEmpty, isTrue);
      expect(updatedGroup2.childLayerIds.contains(layerId), isTrue);
    });

    test('moveLayerBetweenGroups - handles nested group movement', () {
      // Setup: Create nested groups (group1 contains layer, move to group2)
      final group1Id = UuidGenerator.generate();
      final group2Id = UuidGenerator.generate();
      final childGroupId = UuidGenerator.generate();
      
      final group1 = Layer(
        id: group1Id,
        name: 'Group1',
        type: 'group',
        childLayerIds: [childGroupId],
      );
      
      final group2 = Layer(
        id: group2Id,
        name: 'Group2',
        type: 'group',
        childLayerIds: [],
      );
      
      final childGroup = Layer(
        id: childGroupId,
        name: 'ChildGroup',
        type: 'group',
        childLayerIds: [],
        parentId: group1Id,
      );
      
      final initialState = LayerStack(
        layers: [group1, group2, childGroup],
        activeLayerIndex: 2,
      );
      
      final notifier = LayerStackNotifier();
      notifier.state = initialState;
      
      // Act: Move childGroup from group1 to group2
      notifier.moveLayerBetweenGroups(2, 1);
      
      // Assert
      final updatedGroup1 = notifier.state.layers[0];
      final updatedGroup2 = notifier.state.layers[1];
      final updatedChildGroup = notifier.state.layers[2];
      
      expect(updatedChildGroup.parentId, group2Id);
      expect(updatedGroup1.childLayerIds.isEmpty, isTrue);
      expect(updatedGroup2.childLayerIds.contains(childGroupId), isTrue);
    });

    test('deleteLayer ungroups children when deleting a group', () {
      // Setup: Create a group with children
      final groupId = UuidGenerator.generate();
      final child1Id = UuidGenerator.generate();
      final child2Id = UuidGenerator.generate();
      
      final group = Layer(
        id: groupId,
        name: 'Group',
        type: 'group',
        childLayerIds: [child1Id, child2Id],
      );
      
      final child1 = Layer(
        id: child1Id,
        name: 'Child1',
        parentId: groupId,
      );
      
      final child2 = Layer(
        id: child2Id,
        name: 'Child2',
        parentId: groupId,
      );
      
      final initialState = LayerStack(
        layers: [group, child1, child2],
        activeLayerIndex: 0,
      );
      
      final notifier = LayerStackNotifier();
      notifier.state = initialState;
      
      // Act: Delete the group layer
      notifier.deleteLayer(0);
      
      // Assert: Group should be deleted, children should have no parent
      expect(notifier.state.layers.length, 2);
      expect(notifier.state.layers[0].name, 'Child1');
      expect(notifier.state.layers[0].parentId, isNull);
      expect(notifier.state.layers[1].name, 'Child2');
      expect(notifier.state.layers[1].parentId, isNull);
    });
  });
}
