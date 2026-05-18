import 'package:flutter/material.dart';

/// Układ master–detail na tablecie / składanym telefonie (idea #145).
class ResponsiveTwoPane extends StatelessWidget {
  const ResponsiveTwoPane({
    super.key,
    required this.enabled,
    required this.listPane,
    required this.detailPane,
    this.listFlex = 2,
    this.detailFlex = 3,
    this.breakpoint = 720,
  });

  final bool enabled;
  final Widget listPane;
  final Widget detailPane;
  final int listFlex;
  final int detailFlex;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    final wide = enabled && MediaQuery.sizeOf(context).width >= breakpoint;
    if (!wide) {
      return detailPane;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: listFlex, child: listPane),
        const VerticalDivider(width: 1),
        Expanded(flex: detailFlex, child: detailPane),
      ],
    );
  }
}
