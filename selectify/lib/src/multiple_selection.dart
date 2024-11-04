import 'package:flutter/material.dart';
import 'package:selectify/selectify.dart';

import 'extension/extension.dart';
import 'mixins/state_mixin.dart';

class MultipleSelection<T> extends StatefulWidget {
  final List<T> items;
  final SelectionItemBuilder<T>? itemBuilder;
  final List<T>? initialValue;
  final ValueChanged<List<T>>? onChanged;
  final SelectionConfig? config;
  final ScrollPhysics? physics;
  final bool Function(T, T)? compareFn;
  final String Function(T)? valueShow;
  final bool shrinkWrap;
  final Axis direction;

  const MultipleSelection._({
    super.key,
    required this.items,
    this.itemBuilder,
    this.initialValue,
    this.onChanged,
    this.config,
    this.physics,
    this.compareFn,
    this.valueShow,
    this.shrinkWrap = false,
    this.direction = Axis.vertical,
  });

  factory MultipleSelection.wrap({
    Key? key,
    required List<T> items,
    SelectionItemBuilder<T>? itemBuilder,
    List<T>? initialValue,
    ValueChanged<List<T>>? onChanged,
    ScrollPhysics? physics,
    bool Function(T, T)? compareFn,
    String Function(T)? valueShow,
    bool shrinkWrap = false,
    SelectionConfig? config,
    Axis direction = Axis.vertical,
  }) {
    return MultipleSelection._(
      key: key,
      items: items,
      itemBuilder: itemBuilder,
      initialValue: initialValue,
      onChanged: onChanged,
      physics: physics,
      compareFn: compareFn,
      valueShow: valueShow,
      shrinkWrap: shrinkWrap,
      direction: direction,
      config: (config ?? SelectionConfig()).copyWith(
        crossAxisCount: 0,
      ),
    );
  }

  factory MultipleSelection.grid({
    Key? key,
    required List<T> items,
    SelectionItemBuilder<T>? itemBuilder,
    List<T>? initialValue,
    ValueChanged<List<T>>? onChanged,
    ScrollPhysics? physics,
    bool Function(T, T)? compareFn,
    String Function(T)? valueShow,
    bool shrinkWrap = false,
    int crossAxisCount = 1,
    SelectionConfig? config,
  }) {
    return MultipleSelection._(
      key: key,
      items: items,
      itemBuilder: itemBuilder,
      initialValue: initialValue,
      onChanged: onChanged,
      physics: physics,
      compareFn: compareFn,
      valueShow: valueShow,
      shrinkWrap: shrinkWrap,
      config: (config ?? SelectionConfig()).copyWith(
        crossAxisCount: crossAxisCount,
      ),
    );
  }

  @override
  State<MultipleSelection<T>> createState() => _MultipleSelectionState<T>();
}

class _MultipleSelectionState<T> extends State<MultipleSelection<T>>
    with SelectionStateMixin<T> {
  List<T> selectedItems = [];
  late bool Function(T, T) compareFn;

  // Configuration for the selection.
  late SelectionConfig config;

  @override
  void initState() {
    super.initState();
    // Set the initial selected items.
    selectedItems = selectedItems = validateSelectedItems(
      widget.items,
      widget.initialValue ?? [],
    );
    compareFn = widget.compareFn ?? (i1, i2) => i1 == i2;
    // Set the selection configuration.
    config = widget.config ?? const SelectionConfig();
  }

  @override
  void didUpdateWidget(covariant MultipleSelection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update the selected item if the initial value has changed.
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        selectedItems = validateSelectedItems(
          widget.items,
          widget.initialValue ?? [],
        );
      });
    }

    // Update the configuration if it has changed.
    if (oldWidget.config != widget.config && widget.config != null) {
      setState(() {
        config = widget.config!;
      });
    }
  }

  List<T> validateSelectedItems(List<T> items, List<T> selectedItems) {
    if (selectedItems.isEmpty) return [];

    return selectedItems.where((item) => items.contains(item)).toList();
  }

  void onTap(T item, bool isSelected) {
    if (isSelected) {
      selectedItems.remove(item);
    } else {
      selectedItems.add(item);
    }
    setState(() {});

    widget.onChanged?.call(selectedItems);
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
      compareFn: (item) =>
          selectedItems.firstWhereOrNull(
            (selectedItem) => compareFn(item, selectedItem),
          ) !=
          null,
      onTap: onTap,
    );

    return buildSelection(context, configuration);
  }
}
