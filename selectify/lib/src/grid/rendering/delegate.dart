import 'package:flutter/rendering.dart';

import 'render_sliver_grid.dart';

/// [SliverSelectionGridDelegate] is responsible for providing configuration and layout information
/// for the grid tiles.
abstract class SliverSelectionGridDelegate {
  const SliverSelectionGridDelegate({
    required this.tileBuilder,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.tileCount,
  })  : assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0);

  /// Spacing between tiles in the main axis direction.
  final double mainAxisSpacing;

  /// Spacing between tiles in the cross axis direction.
  final double crossAxisSpacing;

  /// A builder function that creates tiles for the grid.
  final IndexedSelectionTileBuilder tileBuilder;

  /// The total number of tiles. If null, the number of tiles is assumed to be infinite.
  final int? tileCount;

  /// Validates the properties of the delegate.
  bool _debugAssertIsValid() {
    assert(mainAxisSpacing >= 0);
    assert(crossAxisSpacing >= 0);
    return true;
  }

  /// Returns the configuration of the grid based on the given constraints.
  SelectionGridConfiguration getConfiguration(SliverConstraints constraints);

  /// Determines if the layout should be updated based on changes to the delegate properties.
  bool shouldRelayout(SliverSelectionGridDelegate oldDelegate) {
    return oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.tileCount != tileCount ||
        oldDelegate.tileBuilder != tileBuilder;
  }
}

/// A delegate that provides a fixed number of tiles in the cross axis for the sliver selection grid.
class SliverSelectionGridDelegateWithFixedCrossAxisCount
    extends SliverSelectionGridDelegate {
  const SliverSelectionGridDelegateWithFixedCrossAxisCount({
    required this.crossAxisCount,
    required super.tileBuilder,
    super.mainAxisSpacing,
    super.crossAxisSpacing,
    super.tileCount,
  }) : assert(crossAxisCount > 0);

  /// The number of tiles in the cross axis.
  final int crossAxisCount;

  @override
  bool _debugAssertIsValid() {
    assert(crossAxisCount > 0);
    return super._debugAssertIsValid();
  }

  @override
  SelectionGridConfiguration getConfiguration(SliverConstraints constraints) {
    assert(_debugAssertIsValid());
    final double usableCrossAxisExtent =
        constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final double cellExtent = usableCrossAxisExtent / crossAxisCount;

    return SelectionGridConfiguration(
      crossAxisCount: crossAxisCount,
      tileBuilder: tileBuilder,
      tileCount: tileCount,
      cellExtent: cellExtent,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(
    covariant SliverSelectionGridDelegateWithFixedCrossAxisCount oldDelegate,
  ) {
    return oldDelegate.crossAxisCount != crossAxisCount ||
        super.shouldRelayout(oldDelegate);
  }
}
