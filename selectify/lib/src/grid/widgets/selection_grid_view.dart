import 'package:flutter/widgets.dart';

import '../rendering/delegate.dart';
import '../rendering/render_sliver_grid.dart';
import 'sliver.dart';

class SelectionGridView extends BoxScrollView {
  SelectionGridView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required this.gridDelegate,
    this.addAutomaticKeepAlive = true,
    bool addRepaintBoundaries = true,
    List<Widget> children = const <Widget>[],
    super.restorationId,
  }) : delegate = SliverChildListDelegate(
          children,
          addAutomaticKeepAlives: addAutomaticKeepAlive,
          addRepaintBoundaries: addRepaintBoundaries,
        );

  SelectionGridView.builder({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required this.gridDelegate,
    required IndexedWidgetBuilder itemBuilder,
    int? itemCount,
    this.addAutomaticKeepAlive = true,
    bool addRepaintBoundaries = true,
    super.restorationId,
  }) : delegate = SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
          addAutomaticKeepAlives: addAutomaticKeepAlive,
          addRepaintBoundaries: addRepaintBoundaries,
        );

  SelectionGridView.countBuilder({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required int crossAxisCount,
    required IndexedWidgetBuilder itemBuilder,
    required IndexedSelectionTileBuilder tileBuilder,
    int? itemCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    this.addAutomaticKeepAlive = true,
    bool addRepaintBoundaries = true,
    super.restorationId,
  })  : gridDelegate = SliverSelectionGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          tileBuilder: tileBuilder,
          tileCount: itemCount,
        ),
        delegate = SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
          addAutomaticKeepAlives: addAutomaticKeepAlive,
          addRepaintBoundaries: addRepaintBoundaries,
        );

  /// The grid delegate that controls the layout of the grid.
  final SliverSelectionGridDelegate gridDelegate;

  /// The delegate that provides children for the grid.
  final SliverChildDelegate delegate;

  /// Whether to add automatic keep-alive for children.
  final bool addAutomaticKeepAlive;

  @override
  Widget buildChildLayout(BuildContext context) {
    return SliverSelectionGrid(
      delegate: delegate,
      gridDelegate: gridDelegate,
      addAutomaticKeepAlive: addAutomaticKeepAlive,
    );
  }
}
