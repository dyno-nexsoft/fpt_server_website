import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';

import 'action_form_controller.dart';
import 'action_param_field.dart';

/// A form generated from `GET /actions/{name}`'s schema — one field per
/// param — so the UI can never drift from what the server actually accepts.
/// Used for every invokable action except `ci.build`, which has its own
/// sectioned form (`CiBuildFormScreen`) because its fields fall into natural
/// groups that a flat list hides.
class ActionFormScreen extends ConsumerStatefulWidget {
  const ActionFormScreen({super.key, required this.actionName});

  final String actionName;

  @override
  ConsumerState<ActionFormScreen> createState() => _ActionFormScreenState();
}

class _ActionFormScreenState extends ConsumerState<ActionFormScreen>
    with ActionFormControllerState<ActionFormScreen> {
  @override
  Widget build(BuildContext context) {
    return buildActionForm(
      context,
      widget.actionName,
      (action) => buildFormScaffold(
        context,
        action,
        title: action.name,
        fields: _buildFields(action),
      ),
    );
  }

  List<Widget> _fieldWidgets(ActionSchema action) => [
    for (final param in action.params)
      ActionParamField(
        param: param,
        controller: controllers[param.name],
        enumValue: enumValues[param.name],
        boolValue: boolValues[param.name] ?? false,
        onEnumChanged: (value) =>
            setState(() => enumValues[param.name] = value),
        onBoolChanged: (value) =>
            setState(() => boolValues[param.name] = value),
      ),
  ];

  /// A fixed two-column grid once there are enough fields to make one
  /// worthwhile, a single full-width column otherwise — two fields spread
  /// across a grid (`ci.replace`'s `url` + `tbchat`) just leaves one column
  /// stretched and the rest of the row (and most of the space below it)
  /// empty, which reads worse than the plain full-width list this is meant
  /// to improve on. Fixed at 2 columns rather than
  /// SliverGridDelegateWithMaxCrossAxisExtent's "as many as fit" — a wide
  /// desktop window fit 4 narrow fields per row, each barely wider than its
  /// own label.
  Widget _buildFields(ActionSchema action) {
    if (action.params.length <= 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: _fieldWidgets(action),
      );
    }
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 60,
        mainAxisSpacing: 12,
        crossAxisSpacing: 16,
      ),
      children: _fieldWidgets(action),
    );
  }
}
