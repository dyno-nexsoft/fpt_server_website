import 'package:flutter/material.dart';

/// The multiline description prompt shared by starting and editing a report —
/// the browser's equivalent of the Discord modal both flows use there.
///
/// Resolves `null` on cancel and the text otherwise, empty string included:
/// filing a report first and writing it later is the normal flow, so an empty
/// submission is a real answer rather than a cancel.
class ReportDescriptionDialog extends StatefulWidget {
  const ReportDescriptionDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.initialValue = '',
  });

  final String title;
  final String confirmLabel;
  final String initialValue;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String initialValue = '',
  }) => showDialog<String>(
    context: context,
    builder: (_) => ReportDescriptionDialog(
      title: title,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
    ),
  );

  @override
  State<ReportDescriptionDialog> createState() =>
      _ReportDescriptionDialogState();
}

class _ReportDescriptionDialogState extends State<ReportDescriptionDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 8,
          minLines: 4,
          decoration: const InputDecoration(
            labelText: 'Content (Markdown)',
            alignLabelWithHint: true,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
