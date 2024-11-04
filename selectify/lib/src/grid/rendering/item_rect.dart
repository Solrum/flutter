/// [ItemRect] holds information about the position and size of an item,
/// including its index in the grid, the number of items it spans in the
/// cross axis, and its offset bounds.
class ItemRect {
  const ItemRect(
    this.index,
    this.crossAxisCount,
    this.minOffset,
    this.maxOffset,
  );

  /// The index of the item in the grid.
  final int index;

  /// The number of cross-axis items that this rectangle spans.
  final int crossAxisCount;

  /// The minimum offset of the item in the main axis.
  final double minOffset;

  /// The maximum offset of the item in the main axis.
  final double maxOffset;
}
