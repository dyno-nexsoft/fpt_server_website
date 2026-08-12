import 'package:flutter/material.dart';

/// Prompts for a template name — shared by the action form's own "Save
/// current as template" and the job detail panel's "Save as template"
/// (saving a past job's params without reopening its form).
class NameTemplateDialog extends StatefulWidget {
  const NameTemplateDialog({super.key, required this.existingNames});

  final Set<String> existingNames;

  @override
  State<NameTemplateDialog> createState() => _NameTemplateDialogState();
}

class _NameTemplateDialogState extends State<NameTemplateDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final overwrites = widget.existingNames.contains(_controller.text.trim());
    return AlertDialog(
      title: const Text('Save as template'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Template name',
          helperText: overwrites ? 'Replaces the existing template.' : null,
        ),
        onSubmitted: (_) => _submit(),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
