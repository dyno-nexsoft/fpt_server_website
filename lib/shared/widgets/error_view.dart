import 'package:flutter/material.dart';

/// Centered "something went wrong" state for a screen whose data failed to
/// load — the icon/message/optional-retry shape most `AsyncValue.error`
/// branches in the app were rebuilding by hand as a bare `Text('$error')`.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            const Icon(Icons.error_outline),
            Text('$error', textAlign: TextAlign.center),
            if (onRetry != null)
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Same failed-to-load state as a single list row instead of a full-screen
/// block — for an error surfacing inside a list/card of otherwise-normal
/// rows (the queue sidebar, a dashboard card) rather than taking over the
/// whole screen.
class ErrorListTile extends StatelessWidget {
  const ErrorListTile({
    super.key,
    required this.error,
    this.title = 'Could not load',
    this.onRetry,
  });

  final Object error;
  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.error_outline),
      title: Text(title),
      subtitle: Text('$error'),
      trailing: onRetry == null
          ? null
          : IconButton(icon: const Icon(Icons.refresh), onPressed: onRetry),
    );
  }
}
