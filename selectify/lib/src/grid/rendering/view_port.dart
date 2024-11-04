/// Represents the viewport offset for a tile, including main axis offsets,
/// trailing scroll offset, and indices for pagination and child tracking.
class TileViewportOffset {
  /// Creates an instance of [TileViewportOffset].
  ///
  /// [mainAxisOffsets] - A list of offsets along the main axis.
  /// [trailingScrollOffset] - The offset at the trailing edge of the viewport.
  /// [pageIndex] - The index of the current page (default is 0).
  /// [firstChildIndex] - The index of the first child in the viewport (default is 0).
  TileViewportOffset(
    List<double> mainAxisOffsets,
    this.trailingScrollOffset, [
    this.pageIndex = 0,
    this.firstChildIndex = 0,
  ]) : mainAxisOffsets = List<double>.from(
          // ignore: require_trailing_commas
          mainAxisOffsets,
        ); // Ensures a copy of the list is made.

  /// The index of the current page in the viewport.
  final int pageIndex;

  /// The index of the first child visible in the viewport.
  final int firstChildIndex;

  /// The scroll offset at the trailing edge of the viewport.
  final double trailingScrollOffset;

  /// A list of offsets along the main axis for the tiles.
  final List<double> mainAxisOffsets;

  @override
  String toString() {
    return '[$pageIndex-$trailingScrollOffset] ($firstChildIndex, $mainAxisOffsets)';
  }
}
