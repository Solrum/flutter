import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'delegate.dart';
import 'item_rect.dart';
import 'selection_tile.dart';
import 'sliver_variable_renderer.dart';
import 'view_port.dart';

typedef IndexedSelectionTileBuilder = SelectionTile? Function(int index);

class RenderSliverSelectionGrid extends VariableRenderSliver {
  /// Creates an instance of [RenderSliverSelectionGrid].
  ///
  /// The [childManager] must not be null and is used to manage child slivers.
  /// The [gridDelegate] defines the layout and characteristics of the grid.
  RenderSliverSelectionGrid({
    required super.childManager,
    required SliverSelectionGridDelegate gridDelegate,
  })  : _gridDelegate = gridDelegate,
        _pageSizeToViewportOffsetMaps =
            HashMap<double, SplayTreeMap<int, TileViewportOffset?>>();

  /// The delegate that controls the layout of the grid.
  ///
  /// This can be accessed to retrieve layout configuration and characteristics.
  SliverSelectionGridDelegate get gridDelegate => _gridDelegate;

  /// The current grid delegate controlling the layout of the grid.
  SliverSelectionGridDelegate _gridDelegate;

  /// Sets the grid delegate for this grid.
  ///
  /// If the new delegate is of a different runtime type or requires relayout,
  /// the render object will mark itself for layout.
  set gridDelegate(SliverSelectionGridDelegate value) {
    if (_gridDelegate == value) {
      return; // No change needed, exit early.
    }
    if (value.runtimeType != _gridDelegate.runtimeType ||
        value.shouldRelayout(_gridDelegate)) {
      markNeedsLayout(); // Mark for layout if the delegate requires it.
    }
    _gridDelegate = value; // Update the grid delegate.
  }

  /// A map that associates page sizes with their corresponding viewport offsets.
  ///
  /// This helps in efficiently managing the layout offsets based on the size of the grid.
  final HashMap<double, SplayTreeMap<int, TileViewportOffset?>>
      _pageSizeToViewportOffsetMaps;

  /// Sets up parent data for a child render object.
  ///
  /// If the child does not have [SliverVariableParentData], it creates a new instance
  /// and assigns it to the child's parent data.
  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverVariableParentData) {
      final data = SliverVariableParentData();
      child.parentData = data; // Assign new parent data to child.
    }
  }

  @override
  void performLayout() {
    childManager.onRenderStart();
    childManager.markUnderflowStatus(false);

    final double scrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    bool reachedEnd = false;
    double trailingScrollOffset = 0;
    double leadingScrollOffset = double.infinity;
    bool visible = false;
    int firstIndex = 0;
    int lastIndex = 0;

    final configuration = _gridDelegate.getConfiguration(constraints);

    final pageSize = configuration.mainAxisOffsetsCacheSize *
        constraints.viewportMainAxisExtent;
    if (pageSize == 0.0) {
      geometry = SliverGeometry.zero;
      childManager.onRenderComplete();
      return;
    }
    final pageIndex = scrollOffset ~/ pageSize;
    assert(pageIndex >= 0);

    final viewportOffsets = _pageSizeToViewportOffsetMaps.putIfAbsent(
      pageSize,
      () => SplayTreeMap<int, TileViewportOffset?>(),
    );

    TileViewportOffset? viewportOffset = viewportOffsets.isEmpty
        ? TileViewportOffset(configuration.generateMainAxisOffsets(), pageSize)
        : viewportOffsets[viewportOffsets.lastKeyBefore(pageIndex + 1)!];

    if (viewportOffsets.isEmpty) {
      viewportOffsets[0] = viewportOffset;
    }
    final mainAxisOffsets = viewportOffset!.mainAxisOffsets.toList();
    final visibleIndices = HashSet<int>();

    for (var index = viewportOffset.firstChildIndex;
        mainAxisOffsets.any((o) => o <= targetEndScrollOffset);
        index++) {
      SliverSelectionGridGeometry? geometry =
          getSliverSelectionGeometry(index, configuration, mainAxisOffsets);
      if (geometry == null) {
        reachedEnd = true;
        break;
      }

      final hasTrailingScrollOffset = geometry.hasTrailingScrollOffset;
      RenderBox? child;

      if (!hasTrailingScrollOffset) {
        child = addAndLayoutChildAtIndex(
          index,
          BoxConstraints.tightFor(width: geometry.crossAxisExtent),
          parentUsesSize: true,
        );
        geometry = geometry.copyWith(mainAxisExtent: paintExtentOf(child!));
      }

      if (!visible &&
          targetEndScrollOffset >= geometry.scrollOffset &&
          scrollOffset <= geometry.trailingScrollOffset) {
        visible = true;
        leadingScrollOffset = geometry.scrollOffset;
        firstIndex = index;
      }

      if (visible) {
        if (hasTrailingScrollOffset) {
          child = addAndLayoutChildAtIndex(
            index,
            geometry.getBoxConstraints(constraints),
          );
        }

        if (child != null) {
          final childParentData = child.parentData! as SliverVariableParentData;
          childParentData.layoutOffset = geometry.scrollOffset;
          childParentData.crossAxisOffset = geometry.crossAxisOffset;
          assert(childParentData.index == index);
        }

        if (indices.contains(index)) {
          visibleIndices.add(index);
        }
      }

      if (geometry.trailingScrollOffset >=
          viewportOffset!.trailingScrollOffset) {
        final nextPageIndex = viewportOffset.pageIndex + 1;
        final nextViewportOffset = TileViewportOffset(
          mainAxisOffsets,
          (nextPageIndex + 1) * pageSize,
          nextPageIndex,
          index,
        );
        viewportOffsets[nextPageIndex] = nextViewportOffset;
        viewportOffset = nextViewportOffset;
      }

      final endOffset =
          geometry.trailingScrollOffset + configuration.mainAxisSpacing;
      for (var i = 0; i < geometry.crossAxisCellCount; i++) {
        mainAxisOffsets[i + geometry.index] = endOffset;
      }

      trailingScrollOffset = math.max(trailingScrollOffset, endOffset);
      lastIndex = index;
    }
    collectGarbage(visibleIndices);

    if (!visible) {
      geometry = scrollOffset > viewportOffset!.trailingScrollOffset
          ? SliverGeometry(
              scrollOffsetCorrection:
                  (pageSize * viewportOffset.pageIndex) - scrollOffset,
            )
          : SliverGeometry.zero;

      if (geometry == SliverGeometry.zero) {
        childManager.onRenderComplete();
      }
      return;
    }

    double estimatedMaxScrollOffset = reachedEnd
        ? trailingScrollOffset
        : childManager.calculateMaxScrollOffsetEstimate(
            constraints,
            firstIndex: firstIndex,
            lastIndex: lastIndex,
            leadingScrollOffset: leadingScrollOffset,
            trailingScrollOffset: trailingScrollOffset,
          );

    assert(
      estimatedMaxScrollOffset >= trailingScrollOffset - leadingScrollOffset,
    );

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      hasVisualOverflow: trailingScrollOffset > targetEndScrollOffset ||
          constraints.scrollOffset > 0.0,
    );

    if (estimatedMaxScrollOffset == trailingScrollOffset) {
      childManager.markUnderflowStatus(true);
    }
    childManager.onRenderComplete();
  }

  static SliverSelectionGridGeometry? getSliverSelectionGeometry(
    int index,
    SelectionGridConfiguration configuration,
    List<double> offsets,
  ) {
    final tile = configuration.getSelectionTile(index);
    if (tile == null) {
      return null;
    }

    final rect =
        _findFirstRectWithCrossAxisCount(tile.crossAxisCellCount, offsets);
    final scrollOffset = rect.minOffset;

    // Calculate rectIndex based on the reverseCrossAxis flag.
    var rectIndex = configuration.reverseCrossAxis
        ? configuration.crossAxisCount - tile.crossAxisCellCount - rect.index
        : rect.index;

    final crossAxisOffset = rectIndex * configuration.cellStride;
    return SliverSelectionGridGeometry(
      scrollOffset: scrollOffset,
      crossAxisOffset: crossAxisOffset,
      mainAxisExtent: tile.mainAxisExtent,
      crossAxisExtent: (configuration.cellStride * tile.crossAxisCellCount) -
          configuration.crossAxisSpacing,
      crossAxisCellCount: tile.crossAxisCellCount,
      index: rect.index,
    );
  }

  static ItemRect _findFirstRectWithCrossAxisCount(
    int crossAxisCount,
    List<double> offsets,
  ) {
    return _findFirstAvailableRect(
      crossAxisCount,
      List.from(offsets),
    );
  }

  /// Finds the first available rectangular block in the provided offsets
  /// that can accommodate the specified cross-axis count.
  ///
  /// The method checks if the found block can fit the required cross-axis
  /// count. If not, it adjusts the offsets of the existing block to its
  /// maximum offset and recursively searches for the next available block
  /// until a suitable one is found.
  static ItemRect _findFirstAvailableRect(
    int crossAxisCount,
    List<double> offsets,
  ) {
    // Find the first available rectangular block based on offsets
    final rect = _findFirstAvailableRectBound(offsets);

    // If the block found cannot accommodate the required cross-axis count
    if (rect.crossAxisCount < crossAxisCount) {
      // Adjust the offsets to the maximum offset of the current block
      for (var i = 0; i < rect.crossAxisCount; ++i) {
        offsets[i + rect.index] = rect.maxOffset;
      }
      // Recursively search for another available block
      return _findFirstAvailableRect(crossAxisCount, offsets);
    } else {
      // Return the found block if it fits the criteria
      return rect;
    }
  }

  /// Finds the first available rect of offsets from the given list.
  ///
  /// The method iterates through the list of offsets to identify the minimum
  /// offset and its contiguous occurrences, while also determining the
  /// maximum offset in the same rect. It returns an `ItemRect` containing
  /// the index of the first offset, the count of contiguous offsets, the
  /// minimum rect offset, and the maximum offset.
  static ItemRect _findFirstAvailableRectBound(List<double> offsets) {
    int index = 0; // Index of the first available rect
    double minOffset = double.infinity; // Initialize min offset
    double maxOffset = double.infinity; // Initialize max offset
    int crossAxisCount = 1; // Count of contiguous offsets
    bool contiguous = false; // Flag to track contiguity of offsets

    for (var i = 0; i < offsets.length; ++i) {
      final offset = offsets[i];

      // Check for a new minimum rect offset
      if (offset < minOffset && !_nearEqual(offset, minOffset)) {
        index = i; // Update index
        maxOffset = minOffset; // Set previous min as max
        minOffset = offset; // Update new min
        crossAxisCount = 1; // Reset contiguous count
        contiguous = true; // Set contiguity flag
      }
      // Check for contiguous offsets
      else if (_nearEqual(offset, minOffset) && contiguous) {
        crossAxisCount++; // Increment contiguous count
      }
      // Check for offsets that are between min and max offsets
      else if (offset < maxOffset &&
          offset > minOffset &&
          !_nearEqual(offset, minOffset)) {
        contiguous = false; // Not contiguous anymore
        maxOffset = offset; // Update max offset
      }
      // Reset contiguity if offset is outside the range
      else {
        contiguous = false;
      }
    }

    return ItemRect(
      index,
      crossAxisCount,
      minOffset,
      maxOffset,
    ); // Return the found rect
  }
}

/// Configuration for a selection grid.
///
/// [SelectionGridConfiguration] holds the configuration parameters for a selection grid
/// such as tile count, spacing, cell dimensions, and the builder for
/// tiles. It helps in calculating the layout and arrangement of tiles
/// in the grid.
@immutable
class SelectionGridConfiguration {
  const SelectionGridConfiguration({
    required this.crossAxisCount,
    required this.tileBuilder,
    required this.cellExtent,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.reverseCrossAxis,
    required this.tileCount,
    this.mainAxisOffsetsCacheSize = 3,
  })  : assert(crossAxisCount > 0),
        assert(cellExtent >= 0),
        assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        assert(mainAxisOffsetsCacheSize > 0),
        cellStride = cellExtent + crossAxisSpacing;

  /// Number of tiles in the cross axis.
  final int crossAxisCount;

  /// The extent of each tile in the main axis.
  final double cellExtent;

  /// Space between tiles in the main axis.
  final double mainAxisSpacing;

  /// Space between tiles in the cross axis.
  final double crossAxisSpacing;

  /// Builder function for creating tiles.
  final IndexedSelectionTileBuilder tileBuilder;

  /// The total number of tiles, if known.
  final int? tileCount;

  /// Indicates if the cross axis is reversed.
  final bool reverseCrossAxis;

  /// The total stride of a cell including spacing.
  final double cellStride;

  /// Size of the cache for main axis offsets.
  final int mainAxisOffsetsCacheSize;

  /// Generates a list of initial offsets for the main axis.
  List<double> generateMainAxisOffsets() =>
      List.generate(crossAxisCount, (i) => 0.0);

  /// Retrieves a selection tile at a specific index, normalizing it if necessary.
  SelectionTile? getSelectionTile(int index) {
    if (tileCount == null || index < tileCount!) {
      return _normalizeTile(tileBuilder(index));
    }
    return null;
  }

  /// Normalizes the provided selection tile to ensure it is a valid tile.
  SelectionTile? _normalizeTile(SelectionTile? selectionTile) {
    if (selectionTile == null) {
      return null;
    }
    return SelectionTile.fit();
  }
}

/// Geometry information for the sliver selection grid.
///
/// [SliverSelectionGridGeometry] contains layout information for a tile in the selection grid,
/// including offsets and dimensions for rendering purposes.
@immutable
class SliverSelectionGridGeometry {
  const SliverSelectionGridGeometry({
    required this.scrollOffset,
    required this.crossAxisOffset,
    required this.mainAxisExtent,
    required this.crossAxisExtent,
    required this.crossAxisCellCount,
    required this.index,
  });

  /// The offset of the tile in the scroll direction.
  final double scrollOffset;

  /// The offset of the tile in the cross axis direction.
  final double crossAxisOffset;

  /// The extent of the tile in the main axis.
  final double? mainAxisExtent;

  /// The extent of the tile in the cross axis.
  final double crossAxisExtent;

  /// The number of cells in the cross axis.
  final int crossAxisCellCount;

  /// The index of the tile.
  final int index;

  /// Checks if the tile has a trailing scroll offset.
  bool get hasTrailingScrollOffset => mainAxisExtent != null;

  /// Computes the trailing scroll offset based on the main axis extent.
  double get trailingScrollOffset => scrollOffset + (mainAxisExtent ?? 0);

  /// Creates a copy of this geometry with optional modifications.
  SliverSelectionGridGeometry copyWith({
    double? scrollOffset,
    double? crossAxisOffset,
    double? mainAxisExtent,
    double? crossAxisExtent,
    int? crossAxisCellCount,
    int? index,
  }) {
    return SliverSelectionGridGeometry(
      scrollOffset: scrollOffset ?? this.scrollOffset,
      crossAxisOffset: crossAxisOffset ?? this.crossAxisOffset,
      mainAxisExtent: mainAxisExtent ?? this.mainAxisExtent,
      crossAxisExtent: crossAxisExtent ?? this.crossAxisExtent,
      crossAxisCellCount: crossAxisCellCount ?? this.crossAxisCellCount,
      index: index ?? this.index,
    );
  }

  /// Converts the geometry into box constraints for layout.
  BoxConstraints getBoxConstraints(SliverConstraints constraints) {
    return constraints.asBoxConstraints(
      minExtent: mainAxisExtent ?? 0.0,
      maxExtent: mainAxisExtent ?? double.infinity,
      crossAxisExtent: crossAxisExtent,
    );
  }

  @override
  String toString() {
    return 'SliverSelectionGridGeometry('
        'scrollOffset: $scrollOffset, '
        'crossAxisOffset: $crossAxisOffset, '
        'mainAxisExtent: $mainAxisExtent, '
        'crossAxisExtent: $crossAxisExtent, '
        'crossAxisCellCount: $crossAxisCellCount, '
        'index: $index)';
  }
}

/// A small value used for comparing floating-point numbers.
const double _epsilon = 0.0001;

/// Checks if two doubles are nearly equal within a small epsilon range.
bool _nearEqual(double d1, double d2) {
  return (d1 - d2).abs() < _epsilon;
}
