import 'package:flutter/material.dart';

import '../../../core/models/action_schema.dart';

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

  String get _label => param.required ? '${param.name} *' : param.name;

  @override
  Widget build(BuildContext context) {
    switch (param.type) {
      case ActionParamType.enumeration:
        return DropdownButtonFormField<String>(
          initialValue: enumValue,
          decoration: InputDecoration(
            labelText: _label,
            helperText: param.description,
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
          subtitle: param.description.isEmpty ? null : Text(param.description),
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
            helperText: param.description,
          ),
          validator: (value) => _validateText(value),
        );
      case ActionParamType.string:
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: _label,
            helperText: param.description,
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
