import 'package:flutter/material.dart';

/// A group heading for a page split into labelled sections — otherwise a
/// stack of cards reads as one undifferentiated list with no indication of
/// why they're grouped the way they are.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(title.toUpperCase(), style: textTheme.labelLarge),
        const Divider(height: 1),
      ],
    );
  }
}
