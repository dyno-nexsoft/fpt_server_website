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
        fields: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: _fieldWidgets(action),
        ),
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
}
