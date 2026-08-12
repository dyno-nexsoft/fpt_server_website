import 'package:flutter/material.dart';

import '../../../core/models/action_schema.dart';
import 'branch_autocomplete_field.dart';

/// One form control generated from an [ActionParam] — the shape of the
/// field (dropdown, switch, text) is entirely derived from `param.type`.
class ActionParamField extends StatelessWidget {
  const ActionParamField({
    super.key,
    required this.param,
    required this.controller,
    required this.enumValue,
    required this.boolValue,
    required this.onEnumChanged,
    required this.onBoolChanged,
  });

  final ActionParam param;
  final TextEditingController? controller;
  final String? enumValue;
  final bool boolValue;
  final ValueChanged<String?> onEnumChanged;
  final ValueChanged<bool> onBoolChanged;

  // The description ("Branch repo tbchat") reads better as the prominent
  // label than the raw param name ("tbchat") — the name moves to the helper
  // slot instead of disappearing, for anyone matching this field back to a
  // REST/CLI flag.
  String get _label {
    final base = param.description.isEmpty ? param.name : param.description;
    return param.required ? '$base *' : base;
  }

  @override
  Widget build(BuildContext context) {
    switch (param.type) {
      case ActionParamType.enumeration:
        return DropdownButtonFormField<String>(
          initialValue: enumValue,
          decoration: InputDecoration(
            labelText: _label,
            helperText: param.name,
          ),
          items: [
            for (final choice in param.choices)
              DropdownMenuItem(value: choice, child: Text(choice)),
          ],
          onChanged: onEnumChanged,
        );
      case ActionParamType.boolean:
        return SwitchListTile(
          title: Text(_label),
          subtitle: Text(param.name),
          value: boolValue,
          onChanged: onBoolChanged,
        );
      case ActionParamType.integer:
      case ActionParamType.number:
        return TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _label,
            helperText: param.name,
          ),
          validator: (value) => _validateText(value),
        );
      case ActionParamType.string:
        if (param.isBranchRef) {
          return BranchAutocompleteField(
            param: param,
            controller: controller!,
            label: _label,
          );
        }
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: _label,
            helperText: param.name,
          ),
          validator: (value) => _validateText(value),
        );
    }
  }

  String? _validateText(String? value) {
    if (param.required && (value == null || value.trim().isEmpty)) {
      return 'Required';
    }
    if (value != null &&
        value.isNotEmpty &&
        param.type == ActionParamType.integer &&
        int.tryParse(value) == null) {
      return 'Must be a whole number';
    }
    if (value != null &&
        value.isNotEmpty &&
        param.type == ActionParamType.number &&
        double.tryParse(value) == null) {
      return 'Must be a number';
    }
    return null;
  }
}
