import 'package:flutter/material.dart';

/// Shows an application dialog and completes only after its closing animation.
///
/// Waiting for the route to settle keeps callers from disposing field
/// controllers or opening another overlay while Flutter still owns the old
/// dialog subtree.
Future<T?> showSettledDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) async {
  final result = await showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
  await Future<void>.delayed(kThemeAnimationDuration);
  return result;
}

class DialogFormColumn extends StatelessWidget {
  const DialogFormColumn({
    required this.children,
    this.spacing = 16,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    super.key,
  });

  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: crossAxisAlignment,
    children: [
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0) SizedBox(height: spacing),
        children[index],
      ],
    ],
  );
}

class DialogBody extends StatelessWidget {
  const DialogBody({required this.child, this.width = 520, super.key});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: child);
}
