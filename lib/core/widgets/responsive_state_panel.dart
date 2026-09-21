import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

class ResponsiveStatePanel extends StatelessWidget {
  const ResponsiveStatePanel({
    required this.message,
    this.title,
    this.icon = Icons.info_outline,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String? title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    container: true,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32),
            if (title != null) ...[
              const SizedBox(height: AppSpacing.compact),
              Text(
                title!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.small),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.medium),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    ),
  );
}
