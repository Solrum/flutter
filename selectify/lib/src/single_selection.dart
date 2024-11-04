import 'package:flutter/material.dart';

import 'mixins/state_mixin.dart';
import 'model/selection_model.dart';

/// A type definition for a function that builds an item widget.
/// Takes the current BuildContext, the item, its index, and a selection state indicator.
typedef SelectionItemBuilder<T> = Widget Function(BuildContext, T, int, bool);

/// A widget that allows for single item selection from a list of items.
/// It supports different layouts: grid, list tile, or wrap.
class SingleSelection<T> extends StatefulWidget {
  /// The list of items to select from.
  final List<T> items;

  /// A builder function to create the UI for each item.
  final SelectionItemBuilder<T>? itemBuilder;

  /// The initially selected item.
  final T? initialValue;

  /// Callback invoked when the selected item changes.
  final ValueChanged<T>? onChanged;

  /// Configuration for the selection layout.
  final SelectionConfig? config;

  /// Scroll physics for the selection view.
  final ScrollPhysics? physics;

  /// A function that defines how to display the item's value.
  final String Function(T)? valueShow;

  final bool Function(T, T?)? compareFn;

  final bool shrinkWrap;

  final Axis direction;

  const SingleSelection._({
    super.key,
    required this.items,
    this.itemBuilder,
    this.initialValue,
    this.onChanged,
    this.config,
    this.physics,
    this.valueShow,
    this.compareFn,
    this.shrinkWrap = false,
    this.direction = Axis.vertical,
  });

  /// Creates a grid layout for the selection items.
  factory SingleSelection.grid({
    Key? key,
    required List<T> items,
    SelectionItemBuilder<T>? itemBuilder,
    T? initialValue,
    int crossAxisCount = 1,
    ValueChanged<T>? onChanged,
    SelectionConfig? config,
    ScrollPhysics? physics,
    String Function(T)? valueShow,
    bool Function(T, T?)? compareFn,
    bool shrinkWrap = false,
  }) {
    return SingleSelection<T>._(
      key: key,
      items: items,
      itemBuilder: itemBuilder,
      initialValue: initialValue,
      onChanged: onChanged,
      physics: physics,
      valueShow: valueShow,
      compareFn: compareFn,
      shrinkWrap: shrinkWrap,
      config: (config ?? SelectionConfig()).copyWith(
        crossAxisCount: crossAxisCount,
      ),
    );
  }

  /// Creates a wrap layout for the selection items.
  factory SingleSelection.wrap({
    Key? key,
    required List<T> items,
    SelectionItemBuilder<T>? itemBuilder,
    T? initialValue,
    ValueChanged<T>? onChanged,
    SelectionConfig? config,
    ScrollPhysics? physics,
    String Function(T)? valueShow,
    bool Function(T, T?)? compareFn,
    bool shrinkWrap = false,
    Axis direction = Axis.vertical,
  }) {
    return SingleSelection<T>._(
      key: key,
      items: items,
      itemBuilder: itemBuilder,
      initialValue: initialValue,
      onChanged: onChanged,
      physics: physics,
      valueShow: valueShow,
      compareFn: compareFn,
      shrinkWrap: shrinkWrap,
      direction: direction,
      config: (config ?? SelectionConfig()).copyWith(
        crossAxisCount: 0,
      ),
    );
  }

  @override
  State<SingleSelection<T>> createState() => _SingleSelectionState<T>();
}

/// The state class for [SingleSelection].
class _SingleSelectionState<T> extends State<SingleSelection<T>>
    with SelectionStateMixin<T> {
  // The currently selected item.
  T? selectedItem;

  // Configuration for the selection.
  late SelectionConfig config;
  late final bool Function(T, T?) compareFn;

  @override
  void initState() {
    super.initState();
    // Set the initial selected item.
    selectedItem = widget.initialValue;
    compareFn = widget.compareFn ?? (i1, i2) => i1 == i2;
    // Set the selection configuration.
    config = widget.config ?? const SelectionConfig();
  }

  @override
  void didUpdateWidget(covariant SingleSelection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update the selected item if the initial value has changed.
    if (oldWidget.initialValue != widget.initialValue) {
      T? selected = widget.initialValue;
      if (widget.initialValue != null) {
        final index = widget.items.indexOf(widget.initialValue as T);
        selected = index == -1 ? null : widget.initialValue;
      }
      setState(() {
        selectedItem = selected;
      });
    }

    // Update the configuration if it has changed.
    if (oldWidget.config != widget.config && widget.config != null) {
      setState(() {
        config = widget.config!;
      });
    }
  }

  void onTap(T item, bool isSelected) {
    if (isSelected) return;

    setState(() {
      selectedItem = item;
    });

    widget.onChanged?.call(item);
  }

  @override
  Widget build(BuildContext context) {
    final configuration = MixinConfiguration(
      items: widget.items,
      direction: widget.direction,
      config: config,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      valueShow: (item) => widget.valueShow?.call(item) ?? item.toString(),
      itemBuilder: widget.itemBuilder,
      compareFn: (item) => compareFn(item, selectedItem),
      onTap: onTap,
    );

    return buildSelection(context, configuration);
  }
}
