import 'package:flutter/material.dart';

/// A failed load, rendered the same way every stand-alone settings section
/// does — an icon, what failed, and the error underneath — instead of each
/// section's `.when(error: ...)` branch dumping a bare `Text('$error')' onto
/// the page with no card around it.
class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.title, required this.error});

  final String title;
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(title),
        subtitle: Text('$error'),
      ),
    );
  }
}
