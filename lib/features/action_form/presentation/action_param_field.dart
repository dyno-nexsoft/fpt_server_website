import 'package:flutter/material.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
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
    this.icon,
  });

  final ActionParam param;
  final TextEditingController? controller;
  final String? enumValue;
  final bool boolValue;
  final ValueChanged<String?> onEnumChanged;
  final ValueChanged<bool> onBoolChanged;

  /// Purely decorative — the generic schema-driven form (every action
  /// besides `ci.build`) leaves this null and gets Material's plain
  /// unadorned field, since there's no per-field meaning to hang an icon on
  /// for an arbitrary action's params.
  final IconData? icon;

  // The description ("Branch repo tbchat") reads better as the prominent
  // label than the raw param name ("tbchat").
  String get _label {
    final base = param.description.isEmpty ? param.name : param.description;
    return param.isRequired ? '$base *' : base;
  }

  Icon? get _prefixIcon => icon == null ? null : Icon(icon);

  @override
  Widget build(BuildContext context) {
    switch (param.type) {
      case ParamType.enumeration:
        return DropdownButtonFormField<String>(
          initialValue: enumValue,
          decoration: InputDecoration(
            labelText: _label,
            prefixIcon: _prefixIcon,
          ),
          items: [
            for (final choice in param.choices)
              DropdownMenuItem(value: choice, child: Text(choice)),
          ],
          onChanged: onEnumChanged,
        );
      case ParamType.boolean:
        return SwitchListTile(
          secondary: _prefixIcon,
          title: Text(_label),
          value: boolValue,
          onChanged: onBoolChanged,
        );
      case ParamType.integer:
      case ParamType.number:
        return TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _label,
            prefixIcon: _prefixIcon,
          ),
          validator: (value) => _validateText(value),
        );
      case ParamType.string:
        if (param.isBranchRef) {
          return BranchAutocompleteField(
            param: param,
            controller: controller!,
            label: _label,
            icon: icon,
          );
        }
        if (param.isStringList) {
          return TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: _label,
              hintText: 'One per line',
              alignLabelWithHint: true,
              prefixIcon: _prefixIcon,
            ),
            minLines: 3,
            maxLines: 6,
            validator: (value) => _validateText(value),
          );
        }
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: _label,
            prefixIcon: _prefixIcon,
          ),
          validator: (value) => _validateText(value),
        );
    }
  }

  String? _validateText(String? value) {
    if (param.isRequired && (value == null || value.trim().isEmpty)) {
      return 'Required';
    }
    if (value != null &&
        value.isNotEmpty &&
        param.type == ParamType.integer &&
        int.tryParse(value) == null) {
      return 'Must be a whole number';
    }
    if (value != null &&
        value.isNotEmpty &&
        param.type == ParamType.number &&
        double.tryParse(value) == null) {
      return 'Must be a number';
    }
    return null;
  }
}
