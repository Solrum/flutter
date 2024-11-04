import 'dart:collection';

import 'package:flutter/rendering.dart';

/// [SliverSelectionTileRenderObjectMixin] allows the render object to maintain a mapping of child
/// render objects by their indices, providing utility methods to manipulate
/// the collection of children.
mixin SliverSelectionTileRenderObjectMixin<ChildType extends RenderObject,
    ParentDataType extends ParentData> on RenderObject {
  // A sorted map to store child render objects indexed by their position.
  final SplayTreeMap<int, ChildType> _childRenderObjects =
      SplayTreeMap<int, ChildType>();

  /// The number of children in this render object.
  int get childCount => _childRenderObjects.length;

  /// An iterable of the children render objects.
  Iterable<ChildType> get children => _childRenderObjects.values;

  /// An iterable of the indices corresponding to the children.
  Iterable<int> get indices => _childRenderObjects.keys;

  /// Validates that the provided child is of the expected type.
  bool debugValidateChild(RenderObject child) {
    assert(() {
      if (child is! ChildType) {
        throw FlutterError(
          'A $runtimeType expected a child of type $ChildType but received a '
          'child of type ${child.runtimeType}.\n'
          'RenderObjects expect specific types of children because they '
          'coordinate with their children during layout and paint. For '
          'example, a RenderSliver cannot be the child of a RenderBox because '
          'a RenderSliver does not understand the RenderBox layout protocol.\n'
          '\n'
          'The $runtimeType that expected a $ChildType child was created by:\n'
          '  $debugCreator\n'
          '\n'
          'The ${child.runtimeType} that did not match the expected child type '
          'was created by:\n'
          '  ${child.debugCreator}\n',
        );
      }
      return true;
    }());
    return true;
  }

  /// Gets the child render object at the specified index.
  ChildType? operator [](int index) => _childRenderObjects[index];

  /// Sets the child render object at the specified index.
  void operator []=(int index, ChildType child) {
    if (index < 0) {
      throw ArgumentError('Index cannot be negative: $index');
    }
    _removeChild(_childRenderObjects[index]);
    adoptChild(child);
    _childRenderObjects[index] = child;
  }

  /// Executes the given function on each child render object.
  void forEachChild(void Function(ChildType child) f) {
    _childRenderObjects.values.forEach(f);
  }

  /// Removes the child at the specified index.
  void remove(int index) {
    final child = _childRenderObjects.remove(index);
    _removeChild(child);
  }

  /// Removes the specified child render object.
  void _removeChild(ChildType? child) {
    if (child != null) {
      dropChild(child);
    }
  }

  /// Removes all child render objects.
  void removeAll() {
    for (var child in _childRenderObjects.values) {
      dropChild(child);
    }
    _childRenderObjects.clear();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (var child in _childRenderObjects.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (var child in _childRenderObjects.values) {
      child.detach();
    }
  }

  @override
  void redepthChildren() {
    for (var child in _childRenderObjects.values) {
      redepthChild(child);
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    for (var child in _childRenderObjects.values) {
      visitor(child);
    }
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> childrenDiagnostics = <DiagnosticsNode>[];
    _childRenderObjects.forEach(
      (index, child) => childrenDiagnostics
          .add(child.toDiagnosticsNode(name: 'child $index')),
    );
    return childrenDiagnostics;
  }
}
