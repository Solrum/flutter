import 'package:flutter/material.dart';
import 'package:selectify/selectify.dart';

import '../common/selection_widget.dart';
import '../extension/extension.dart';
import '../grid/grid.dart';

class MixinConfiguration<T> {
  final List<T> items;
  final Axis direction;
  final SelectionConfig config;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final String Function(T) valueShow;
  final SelectionItemBuilder<T>? itemBuilder;
  final bool Function(T) compareFn;
  final Function(T, bool) onTap;

  MixinConfiguration({
    required this.items,
    required this.direction,
    required this.config,
    required this.physics,
    required this.shrinkWrap,
    required this.valueShow,
    required this.itemBuilder,
    required this.compareFn,
    required this.onTap,
  });
}

mixin SelectionStateMixin<T> {
  Widget buildSelection(
    BuildContext context,
    MixinConfiguration<T> configuration,
  ) {
    final theme = Theme.of(context);

    final config = configuration.config;

    // Item builder function to create each item widget.
    itemBuilder(context, item, index) => _buildItem(
          theme: theme,
          item: item,
          index: index,
          configuration: configuration,
          context: context,
        );

    // Choose layout based on crossAxisCount.
    if (config.crossAxisCount == 0) {
      Widget child = Wrap(
        spacing: config.mainAxisSpacing,
        runSpacing: config.crossAxisSpacing,
        children: configuration.items
            .mapIndexed(
              (index, item) => itemBuilder(context, item, index),
            )
            .toList(),
      );

      if (configuration.direction == Axis.horizontal) {
        child = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: child,
        );
      }

      return child;
    }

    return SelectionGridView.countBuilder(
      key: ValueKey(config.crossAxisCount),
      physics: configuration.physics,
      itemCount: configuration.items.length,
      crossAxisCount: config.crossAxisCount,
      mainAxisSpacing: config.mainAxisSpacing,
      crossAxisSpacing: config.crossAxisSpacing,
      shrinkWrap: configuration.shrinkWrap,
      itemBuilder: (context, index) =>
          itemBuilder(context, configuration.items[index], index),
      tileBuilder: (index) => const SelectionTile.fit(),
    );
  }

  /// Builds a single item widget based on the selection state.
  Widget _buildItem({
    required MixinConfiguration<T> configuration,
    required ThemeData theme,
    required T item,
    required int index,
    required BuildContext context,
  }) {
    final colorScheme = theme.colorScheme;

    final isSelected = configuration.compareFn(item);
    final enable =
        (item is SelectionModel && item.enable) || item is! SelectionModel;

    if (configuration.itemBuilder != null) {
      // Use custom item builder if provided.
      return GestureDetector(
        onTap: () => configuration.onTap(item, isSelected),
        child: configuration.itemBuilder!(context, item, index, isSelected),
      );
    }

    // Function to return the display value of the item.
    String valueShow(T item) {
      String str = '';

      if (item is SelectionModel) {
        // Get value display from SelectionModel.
        str = item.valueShow ?? item.code.toString();
      } else {
        // Use the provided valueShow function or fallback to toString.
        str = configuration.valueShow.call(item);
      }
      return str;
    }

    // Define styles based on selection state.
    final style = isSelected
        ? configuration.config.textStyle.copyWith(color: colorScheme.onPrimary)
        : configuration.config.textStyle;
    final borderColor =
        isSelected ? theme.primaryColorDark : theme.dividerColor;
    final backgroundColor =
        isSelected ? colorScheme.inversePrimary : colorScheme.onPrimary;

    return SelectionWidget(
      onTap: () => configuration.onTap(item, isSelected),
      height: configuration.config.itemHeight,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      radius: configuration.config.radius,
      valueShow: valueShow(item),
      style: style,
      enable: enable,
    );
  }
}
