/// Represents a selection tile that defines layout properties for a grid or tile-based structure.
///
/// The [SelectionTile] can be used to control the number of cells along the cross-axis
/// and to optionally specify the extent and count of cells along the main axis.
class SelectionTile {
  /// Creates a [SelectionTile] that fits the content.
  ///
  /// The tile will have a default cross-axis cell count of 1, with no specific
  /// main axis extent or cell count defined.
  const SelectionTile.fit()
      : crossAxisCellCount = 1,
        mainAxisExtent = null,
        mainAxisCellCount = null;

  /// The number of cells in the cross axis.
  final int crossAxisCellCount;

  /// The number of cells in the main axis, or `null` if not specified.
  final double? mainAxisCellCount;

  /// The extent (size) of the tile along the main axis, or `null` if not specified.
  final double? mainAxisExtent;

  /// Indicates whether the tile is designed to fit its content,
  /// which is the case if both [mainAxisCellCount] and [mainAxisExtent] are `null`.
  bool get fitContent => mainAxisCellCount == null && mainAxisExtent == null;
}
