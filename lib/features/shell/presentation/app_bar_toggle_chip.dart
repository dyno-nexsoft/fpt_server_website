import 'package:flutter/material.dart';

/// An app-bar control that's a full [ActionChip] normally, or just its icon
/// via [IconButton] when [compact] (a phone-width bar has no room to spare
/// for a label) — the shape [StatusChipsBar] and [ConnectControl] share, so
/// Running/Queued and Sign-out/Connect all read as one consistent control
/// style instead of three separately hand-rolled ones.
class AppBarToggleChip extends StatelessWidget {
  const AppBarToggleChip({
    super.key,
    required this.compact,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool compact;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return compact
        ? IconButton(tooltip: label, icon: Icon(icon), onPressed: onPressed)
        : ActionChip(
            avatar: Icon(icon),
            label: Text(label),
            onPressed: onPressed,
          );
  }
}
