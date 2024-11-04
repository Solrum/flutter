import 'dart:collection';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../rendering/delegate.dart';
import '../rendering/render_sliver_grid.dart';
import '../rendering/sliver_variable_renderer.dart';

abstract class SliverVariableWidget extends SliverWithKeepAliveWidget {
  const SliverVariableWidget({
    super.key,
    required this.delegate,
    this.addAutomaticKeepAlive = true,
  });

  final bool addAutomaticKeepAlive;

  final SliverChildDelegate delegate;

  @override
  SliverVariableElement createElement() => SliverVariableElement(
        this,
        addAutomaticKeepAlive: addAutomaticKeepAlive,
      );

  @override
  VariableRenderSliver createRenderObject(BuildContext context);

  double? calculateMaxScrollOffsetEstimate(
    SliverConstraints constraints,
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) {
    assert(lastIndex >= firstIndex);
    return delegate.estimateMaxScrollOffset(
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<SliverChildDelegate>('delegate', delegate),
    );
  }
}

class SliverVariableElement extends RenderObjectElement
    implements RenderSliverVariableChildManager {
  /// The [addAutomaticKeepAlive] parameter determines if automatic keep-alive
  /// should be applied to the children.
  SliverVariableElement(
    SliverVariableWidget super.widget, {
    this.addAutomaticKeepAlive = true,
  });

  final bool addAutomaticKeepAlive;

  /// Returns the widget associated with this element as a SliverVariableWidget.
  @override
  SliverVariableWidget get widget => super.widget as SliverVariableWidget;

  /// Returns the render object associated with this element as VariableRenderSliver.
  @override
  VariableRenderSliver get renderObject =>
      super.renderObject as VariableRenderSliver;

  /// Updates the element with a new widget and decides whether to rebuild
  /// based on changes in the delegate.
  @override
  void update(covariant SliverVariableWidget newWidget) {
    final SliverVariableWidget oldWidget = widget;
    super.update(newWidget);
    final SliverChildDelegate newDelegate = newWidget.delegate;
    final SliverChildDelegate oldDelegate = oldWidget.delegate;

    // Rebuild if the delegate has changed and requires a rebuild.
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType ||
            newDelegate.shouldRebuild(oldDelegate))) {
      performRebuild();
    }
  }

  // Maps to store child widgets and their associated elements.
  final Map<int, Widget?> _childWidgetMaps = HashMap<int, Widget?>();
  final SplayTreeMap<int, Element> _childElements =
      SplayTreeMap<int, Element>();

  /// Performs the rebuild of children in this element.
  @override
  void performRebuild() {
    _childWidgetMaps.clear();
    super.performRebuild();
    assert(_currentlyUpdatingChildIndex == null);
    try {
      late final int firstIndex;
      late final int lastIndex;

      // Determine the range of children to rebuild.
      if (_childElements.isEmpty) {
        firstIndex = 0;
        lastIndex = 0;
      } else if (_didUnderflow) {
        firstIndex = _childElements.firstKey()!;
        lastIndex = _childElements.lastKey()! + 1;
      } else {
        firstIndex = _childElements.firstKey()!;
        lastIndex = _childElements.lastKey()!;
      }

      // Update children from firstIndex to lastIndex.
      for (int index = firstIndex; index <= lastIndex; ++index) {
        _currentlyUpdatingChildIndex = index;
        final Element? newChild =
            updateChild(_childElements[index], _build(index), index);
        if (newChild != null) {
          _childElements[index] = newChild;
        } else {
          _childElements.remove(index);
        }
      }
    } finally {
      _currentlyUpdatingChildIndex = null;
    }
  }

  /// Builds a child widget at the given index and caches it.
  Widget? _build(int index) {
    return _childWidgetMaps.putIfAbsent(
      index,
      () => widget.delegate.build(this, index),
    );
  }

  /// Instantiates a child at the specified index.
  @override
  void instantiateChildAtIndex(int index) {
    assert(_currentlyUpdatingChildIndex == null);
    owner!.buildScope(this, () {
      Element? newChild;
      try {
        _currentlyUpdatingChildIndex = index;
        newChild = updateChild(_childElements[index], _build(index), index);
      } finally {
        _currentlyUpdatingChildIndex = null;
      }
      if (newChild != null) {
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    });
  }

  /// Updates a child element with a new widget and maintains parent data.
  @override
  Element? updateChild(Element? child, Widget? newWidget, dynamic newSlot) {
    final oldParentData =
        child?.renderObject?.parentData as SliverVariableParentData?;
    final Element? newChild = super.updateChild(child, newWidget, newSlot);
    final newParentData =
        newChild?.renderObject?.parentData as SliverVariableParentData?;

    // Automatically keep alive if specified.
    if (addAutomaticKeepAlive && newParentData != null) {
      newParentData.keepAlive = true;
    }

    // Retain layout offset from old parent data if applicable.
    if (oldParentData != newParentData &&
        oldParentData != null &&
        newParentData != null) {
      newParentData.layoutOffset = oldParentData.layoutOffset;
    }

    return newChild;
  }

  /// Forgets a child element and removes it from the child elements map.
  @override
  void forgetChild(Element child) {
    assert(child.slot != null);
    assert(_childElements.containsKey(child.slot));
    _childElements.remove(child.slot);
    super.forgetChild(child);
  }

  /// Disposes of a child render box.
  @override
  void disposeChildRenderBox(RenderBox child) {
    final int index = renderObject.indexOf(child);
    assert(_currentlyUpdatingChildIndex == null);
    assert(index >= 0);
    owner!.buildScope(this, () {
      assert(_childElements.containsKey(index));
      try {
        _currentlyUpdatingChildIndex = index;
        final Element? result = updateChild(_childElements[index], null, index);
        assert(result == null);
      } finally {
        _currentlyUpdatingChildIndex = null;
      }
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  /// Extrapolates the maximum scroll offset based on the current indices and offsets.
  double? _extrapolateMaxScrollOffset(
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  ) {
    final int? childCount = widget.delegate.estimatedChildCount;
    if (childCount == null) {
      return double.infinity;
    }
    if (lastIndex == childCount - 1) {
      return trailingScrollOffset;
    }
    final int reifiedCount = lastIndex! - firstIndex! + 1;
    final double averageExtent =
        (trailingScrollOffset! - leadingScrollOffset!) / reifiedCount;
    final int remainingCount = childCount - lastIndex - 1;
    return trailingScrollOffset + averageExtent * remainingCount;
  }

  /// Calculates an estimated maximum scroll offset based on constraints and indices.
  @override
  double calculateMaxScrollOffsetEstimate(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  }) {
    return widget.calculateMaxScrollOffsetEstimate(
          constraints,
          firstIndex!,
          lastIndex!,
          leadingScrollOffset!,
          trailingScrollOffset!,
        ) ??
        _extrapolateMaxScrollOffset(
          firstIndex,
          lastIndex,
          leadingScrollOffset,
          trailingScrollOffset,
        )!;
  }

  /// Returns the number of children based on the estimated child count from the delegate.
  @override
  int get childCount => widget.delegate.estimatedChildCount ?? 0;

  /// Called at the start of the render process.
  @override
  void onRenderStart() {
    assert(assertRenderChildListLocked());
  }

  /// Called at the end of the render process, notifying the delegate of the layout completion.
  @override
  void onRenderComplete() {
    assert(assertRenderChildListLocked());
    final int firstIndex = _childElements.firstKey() ?? 0;
    final int lastIndex = _childElements.lastKey() ?? 0;
    widget.delegate.didFinishLayout(firstIndex, lastIndex);
  }

  // The index of the currently updating child.
  int? _currentlyUpdatingChildIndex;

  /// Asserts that the child list is locked during rendering.
  @override
  bool assertRenderChildListLocked() {
    assert(_currentlyUpdatingChildIndex == null);
    return true;
  }

  /// Updates the render index of a child element.
  @override
  void updateChildRenderIndex(RenderBox child) {
    assert(_currentlyUpdatingChildIndex != null);
    final childParentData = child.parentData! as SliverVariableParentData;
    childParentData.index = _currentlyUpdatingChildIndex;
  }

  // Indicates whether the element has underflowed.
  bool _didUnderflow = false;

  /// Marks the underflow status of the element.
  @override
  void markUnderflowStatus(bool value) {
    _didUnderflow = value;
  }

  /// Inserts a child render object at a specified slot.
  @override
  void insertRenderObjectChild(covariant RenderBox child, int slot) {
    assert(_currentlyUpdatingChildIndex == slot);
    assert(renderObject.debugValidateChild(child));
    renderObject[_currentlyUpdatingChildIndex!] = child;
    assert(() {
      final childParentData = child.parentData! as SliverVariableParentData;
      assert(slot == childParentData.index);
      return true;
    }());
  }

  /// Moves a child render object from one slot to another.
  @override
  void moveRenderObjectChild(
    covariant RenderObject child,
    covariant Object? oldSlot,
    covariant Object? newSlot,
  ) {
    assert(false); // This operation is not supported.
  }

  /// Removes a child render object from a specified slot.
  @override
  void removeRenderObjectChild(
    covariant RenderObject child,
    covariant Object? slot,
  ) {
    assert(_currentlyUpdatingChildIndex != null);
    renderObject.remove(_currentlyUpdatingChildIndex!);
  }

  /// Visits all children elements and applies the visitor function.
  @override
  void visitChildren(ElementVisitor visitor) {
    _childElements.values.toList().forEach(visitor);
  }

  /// Visits on-stage children elements and applies the visitor function.
  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    _childElements.values.where((Element child) {
      final parentData =
          child.renderObject!.parentData as SliverMultiBoxAdaptorParentData?;
      late double itemExtent;

      // Determine the item extent based on the rendering axis.
      switch (renderObject.constraints.axis) {
        case Axis.horizontal:
          itemExtent = child.renderObject!.paintBounds.width;
          break;
        case Axis.vertical:
          itemExtent = child.renderObject!.paintBounds.height;
          break;
      }

      // Check if the child is on-stage based on its layout offset.
      return parentData!.layoutOffset! <
              renderObject.constraints.scrollOffset +
                  renderObject.constraints.remainingPaintExtent &&
          parentData.layoutOffset! + itemExtent >
              renderObject.constraints.scrollOffset;
    }).forEach(visitor);
  }
}

class SliverSelectionGrid extends SliverVariableWidget {
  const SliverSelectionGrid({
    super.key,
    required super.delegate,
    required this.gridDelegate,
    super.addAutomaticKeepAlive,
  });

  SliverSelectionGrid.countBuilder({
    super.key,
    required int crossAxisCount,
    required IndexedSelectionTileBuilder tileBuilder,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    bool addAutomaticKeepAlive = true,
  })  : gridDelegate = SliverSelectionGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          tileBuilder: tileBuilder,
          tileCount: itemCount,
        ),
        super(
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            childCount: itemCount,
            addAutomaticKeepAlives: addAutomaticKeepAlive,
          ),
        );

  final SliverSelectionGridDelegate gridDelegate;

  @override
  RenderSliverSelectionGrid createRenderObject(BuildContext context) {
    final element = context as SliverVariableElement;
    return RenderSliverSelectionGrid(
      childManager: element,
      gridDelegate: gridDelegate,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverSelectionGrid renderObject,
  ) {
    renderObject.gridDelegate = gridDelegate;
  }
}
