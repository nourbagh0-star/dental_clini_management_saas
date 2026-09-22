import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';

class WorkspacePage extends StatelessWidget {
  const WorkspacePage({
    required this.title,
    required this.child,
    this.actions = const [],
    this.leading,
    this.onBack,
    this.showBackButton = true,
    this.floatingActionButton,
    this.maximumWidth = AppSpacing.wideContentWidth,
    this.scrollable = false,
    super.key,
  });

  final Widget title;
  final Widget child;
  final List<Widget> actions;
  final Widget? leading;
  final VoidCallback? onBack;
  final bool showBackButton;
  final Widget? floatingActionButton;
  final double maximumWidth;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final layout = AppBreakpoints.of(context);
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maximumWidth),
        child: child,
      ),
    );
    if (scrollable) content = SingleChildScrollView(child: content);

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && showBackButton) {
      effectiveLeading = IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (onBack != null) {
            onBack!();
          } else if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/dashboard');
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: title,
        leading: effectiveLeading,
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        top: false,
        child: Padding(padding: AppInsets.page(layout), child: content),
      ),
    );
  }
}
