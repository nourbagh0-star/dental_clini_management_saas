import 'package:flutter/widgets.dart';

import '../../app/theme/app_tokens.dart';

class ResponsiveRecordView extends StatelessWidget {
  const ResponsiveRecordView({
    required this.compact,
    required this.expanded,
    this.expandAt = AppBreakpoints.mobile,
    super.key,
  });

  final Widget compact;
  final Widget expanded;
  final double expandAt;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        constraints.maxWidth < expandAt ? compact : expanded,
  );
}
