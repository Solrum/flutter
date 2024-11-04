import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'render_object_mixin.dart';

abstract class RenderSliverVariableChildManager {
  /// Instantiates a child at the specified index.
  void instantiateChildAtIndex(int index);

  /// Disposes of the given [child] RenderBox.
  void disposeChildRenderBox(RenderBox child);

  /// Estimates the maximum scroll offset based on the given constraints.
  double calculateMaxScrollOffsetEstimate(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  });

  /// Returns the number of children.
  int get childCount;

  /// Updates the index of the given [child] in the child manager.
  void updateChildRenderIndex(RenderBox child);

  /// Marks the underflow status for child management.
  void markUnderflowStatus(bool value);

  /// Called when rendering starts.
  void onRenderStart() {}

  /// Called when rendering completes.
  void onRenderComplete() {}

  /// Checks if the render child list is locked.
  bool assertRenderChildListLocked() => true;
}

/// Parent data class for children of [VariableRenderSliver].
class SliverVariableParentData extends SliverMultiBoxAdaptorParentData {
  /// The cross-axis offset for the child.
  late double crossAxisOffset;

  /// Whether the child is kept alive.
  bool _keptAlive = false;

  @override
  String toString() => 'crossAxisOffset=$crossAxisOffset; ${super.toString()}';
}

/// A render object that uses a variable number of children.
abstract class VariableRenderSliver extends RenderSliver
    with
        SliverSelectionTileRenderObjectMixin<RenderBox,
            SliverVariableParentData>,
        RenderSliverWithKeepAliveMixin,
        RenderSliverHelpers {
  /// Creates a [VariableRenderSliver] with the given [childManager].
  VariableRenderSliver({
    required RenderSliverVariableChildManager childManager,
  }) : _childManager = childManager;

  /// Returns the child manager.
  @protected
  RenderSliverVariableChildManager get childManager => _childManager;
  final RenderSliverVariableChildManager _childManager;

  /// Keeps track of children that are kept alive.
  final Map<int, RenderBox> _keepAliveBucket = <int, RenderBox>{};

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverVariableParentData) {
      child.parentData = SliverVariableParentData();
    }
  }

  @override
  void adoptChild(RenderObject child) {
    super.adoptChild(child);
    final childParentData = child.parentData! as SliverVariableParentData;
    if (!childParentData._keptAlive) {
      childManager.updateChildRenderIndex(child as RenderBox);
    }
  }

  /// Asserts that the render child list is locked.
  bool _assertRenderChildListLocked() =>
      childManager.assertRenderChildListLocked();

  @override
  void remove(int index) {
    final RenderBox? child = this[index] ?? _keepAliveBucket.remove(index);

    if (child == null) return;

    final childParentData = child.parentData! as SliverVariableParentData;

    if (childParentData._keptAlive) {
      assert(_keepAliveBucket[childParentData.index!] == child);
      _keepAliveBucket.remove(childParentData.index);
    } else {
      super.remove(index);
    }

    dropChild(child);
  }

  @override
  void removeAll() {
    super.removeAll();
    _keepAliveBucket.values.forEach(dropChild);
    _keepAliveBucket.clear();
  }

  /// Creates or retrieves the child at the specified index.
  void _createOrRetrieveChildAtIndex(int index) {
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      assert(constraints == this.constraints);

      final RenderBox? child = _keepAliveBucket.remove(index);
      if (child != null) {
        final childParentData = child.parentData! as SliverVariableParentData;
        assert(childParentData._keptAlive);

        childParentData._keptAlive = false;
        this[index] = child;
      } else {
        _childManager.instantiateChildAtIndex(index);
      }
    });
  }

  /// Disposes or caches the child at the specified index.
  void _disposeOrCacheChildAtIndex(int index) {
    final RenderBox child = this[index]!;
    final childParentData = child.parentData! as SliverVariableParentData;

    if (childParentData.keepAlive) {
      remove(index);
      _keepAliveBucket[childParentData.index!] = child;
      super.adoptChild(child);
      childParentData._keptAlive = true;
    } else {
      _childManager.disposeChildRenderBox(child);
      assert(child.parent == null);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (var child in _keepAliveBucket.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (var child in _keepAliveBucket.values) {
      child.detach();
    }
  }

  @override
  void redepthChildren() {
    super.redepthChildren();
    _keepAliveBucket.values.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    super.visitChildren(visitor);
    _keepAliveBucket.values.forEach(visitor);
  }

  /// Adds a child at the specified index if it can be retrieved or created.
  bool addChild(int index) {
    assert(_assertRenderChildListLocked());
    _createOrRetrieveChildAtIndex(index);
    final child = this[index];
    if (child != null) {
      assert(indexOf(child) == index);
      return true;
    }
    childManager.markUnderflowStatus(true);
    return false;
  }

  /// Adds and lays out a child at the specified index.
  RenderBox? addAndLayoutChildAtIndex(
    int index,
    BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    assert(_assertRenderChildListLocked());

    _createOrRetrieveChildAtIndex(index);
    final RenderBox? child = this[index];

    if (child == null) {
      childManager.markUnderflowStatus(true);
      return null;
    }

    assert(indexOf(child) == index);
    child.layout(constraints, parentUsesSize: parentUsesSize);
    return child;
  }

  /// Collects garbage by removing non-visible children and disposing of them.
  @protected
  void collectGarbage(Set<int> visibleIndices) {
    assert(_assertRenderChildListLocked());
    assert(childCount >= visibleIndices.length);

    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      final nonVisibleIndices =
          Set<int>.from(indices).difference(visibleIndices);
      nonVisibleIndices.forEach(_disposeOrCacheChildAtIndex);

      final disposableChildren = _keepAliveBucket.values.where((child) {
        final parentData = child.parentData! as SliverVariableParentData;
        return !parentData.keepAlive;
      }).toList();

      disposableChildren.forEach(_childManager.disposeChildRenderBox);

      assert(
        _keepAliveBucket.values.every((child) {
          final parentData = child.parentData! as SliverVariableParentData;
          return parentData.keepAlive;
        }),
      );
    });
  }

  /// Returns the index of the given [child].
  int indexOf(RenderBox child) {
    final childParentData = child.parentData! as SliverVariableParentData;
    assert(childParentData.index != null);
    return childParentData.index!;
  }

  /// Calculates the paint extent of the given [child].
  @protected
  double paintExtentOf(RenderBox child) {
    assert(child.hasSize);
    switch (constraints.axis) {
      case Axis.horizontal:
        return child.size.width;
      case Axis.vertical:
        return child.size.height;
    }
  }

  @override
  bool hitTestChildren(
    HitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    for (final child in children) {
      if (hitTestBoxChild(
        BoxHitTestResult.wrap(result),
        child,
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
      )) {
        return true;
      }
    }
    return false;
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    return childScrollOffset(child)! - constraints.scrollOffset;
  }

  @override
  double childCrossAxisPosition(RenderBox child) {
    final childParentData = child.parentData! as SliverVariableParentData;
    return childParentData.crossAxisOffset;
  }

  @override
  double? childScrollOffset(RenderObject child) {
    assert(child.parent == this);
    final childParentData = child.parentData! as SliverVariableParentData;
    assert(childParentData.layoutOffset != null);
    return childParentData.layoutOffset;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    applyPaintTransformForBoxChild(child as RenderBox, transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(
        child,
        offset +
            Offset(
              childCrossAxisPosition(child),
              childMainAxisPosition(child),
            ),
      );
    }
  }
}
