import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shared yes/no confirmation prompt — every action that shouldn't fire on a
/// single stray tap (cancel a build, clear history, restart the server) asks
/// through this one dialog instead of each screen hand-rolling its own
/// `AlertDialog`, so the wording and button styling stay consistent.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    this.confirmLabel = 'Confirm',
    this.isDangerous = false,
  });

  final String title;
  final String body;
  final String confirmLabel;

  /// Styles the confirm button with [AppTheme.destructiveButtonStyle] — for
  /// actions with no undo (cancelling a build, clearing history) rather than
  /// merely disruptive ones (restart, hot reload).
  final bool isDangerous;

  /// Shows the dialog and resolves `true` only if the user tapped confirm —
  /// dismissing it any other way (the Cancel button, tapping outside, back
  /// button) resolves `false` rather than `null`, so callers never need to
  /// null-check the result.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
    String confirmLabel = 'Confirm',
    bool isDangerous = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        isDangerous: isDangerous,
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: isDangerous
              ? AppTheme.destructiveButtonStyle(Theme.of(context).colorScheme)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
