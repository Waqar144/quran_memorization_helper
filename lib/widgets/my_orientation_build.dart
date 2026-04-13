import 'package:flutter/material.dart';

class MyOrientationBuilder extends StatelessWidget {
  const MyOrientationBuilder({super.key, required this.builder});

  final OrientationWidgetBuilder builder;

  Widget _buildWithConstraints(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    // If the constraints are fully unbounded (i.e., maxWidth and maxHeight are
    // both infinite), we prefer Orientation.portrait because its more common to
    // scroll vertically then horizontally.
    final Orientation orientation =
        constraints.maxWidth > (constraints.maxHeight * 1.2)
            ? Orientation.landscape
            : Orientation.portrait;
    return builder(context, orientation);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _buildWithConstraints);
  }
}
