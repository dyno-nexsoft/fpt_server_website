import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';

import '../../../shared/utils/responsive.dart';
import 'action_form_controller.dart';
import 'action_param_field.dart';

/// The dedicated form for `ci.build` ("New build"), replacing the generic
/// schema-generated form because this action's fields fall into natural
/// groups a flat grid hides: the six branch/module fields are all "source
/// control" inputs, platform/environment are one decision, and release notes
/// is a paragraph. Field *values* still come from the same [ActionSchema] and
/// submission goes through the same [ActionFormControllerState] as every
/// other form, so behaviour can never drift from the generic one.
class CiBuildFormScreen extends ConsumerStatefulWidget {
  const CiBuildFormScreen({super.key});

  static const actionName = 'ci.build';

  @override
  ConsumerState<CiBuildFormScreen> createState() => _CiBuildFormScreenState();
}

class _CiBuildFormScreenState extends ConsumerState<CiBuildFormScreen>
    with ActionFormControllerState<CiBuildFormScreen> {
  @override
  Widget build(BuildContext context) {
    return buildActionForm(
      context,
      CiBuildFormScreen.actionName,
      (action) => buildFormScaffold(
        context,
        action,
        title: 'New build',
        fields: _buildFields(action),
      ),
    );
  }

  ActionParam _param(ActionSchema action, String name) =>
      action.params.firstWhere((p) => p.name == name);

  Widget _buildFields(ActionSchema action) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _SectionTitle('Source control & modules'),
      const SizedBox(height: 16),
      _fieldRow(action, 'tbchat', 'database'),
      const SizedBox(height: 12),
      _fieldRow(action, 'im', 'wallet'),
      const SizedBox(height: 12),
      _fieldRow(action, 'cloud_storage', 'socialfi'),
      const SizedBox(height: 24),
      const _SectionTitle('Target environment'),
      const SizedBox(height: 16),
      _fieldRow(action, 'platform', 'environment'),
      const SizedBox(height: 24),
      const _SectionTitle('Details'),
      const SizedBox(height: 16),
      _releaseNotesField(_param(action, 'release_notes')),
    ],
  );

  /// Two fields side by side on desktop, stacked on mobile — the branch and
  /// module fields are related pairs (tbchat/database, im/wallet, ...), so
  /// they read better as a pair than as two full-width rows.
  Widget _fieldRow(ActionSchema action, String first, String second) {
    final left = ActionParamField(
      param: _param(action, first),
      controller: controllers[first],
      enumValue: enumValues[first],
      boolValue: boolValues[first] ?? false,
      onEnumChanged: (value) => setState(() => enumValues[first] = value),
      onBoolChanged: (value) => setState(() => boolValues[first] = value),
    );
    final right = ActionParamField(
      param: _param(action, second),
      controller: controllers[second],
      enumValue: enumValues[second],
      boolValue: boolValues[second] ?? false,
      onEnumChanged: (value) => setState(() => enumValues[second] = value),
      onBoolChanged: (value) => setState(() => boolValues[second] = value),
    );
    if (isMobileWidth(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [left, right],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Expanded(child: left),
        Expanded(child: right),
      ],
    );
  }

  /// Release notes are a paragraph, not a one-line input — a tall field
  /// instead of the generic form's single-line text box.
  Widget _releaseNotesField(ActionParam param) => TextFormField(
    controller: controllers[param.name],
    minLines: 4,
    maxLines: 8,
    decoration: InputDecoration(
      labelText: param.description,
      alignLabelWithHint: true,
    ),
  );
}

/// A group heading for the sections a dedicated form is split into — the
/// flat generated form has no such grouping, which is exactly why it reads
/// as one undifferentiated wall of fields.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(title.toUpperCase(), style: theme.textTheme.labelLarge),
        const Divider(height: 1),
      ],
    );
  }
}
