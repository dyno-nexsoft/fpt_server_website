import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/catalogue_providers.dart';

/// A branch-name field with the same live suggestions Discord's `/build`
/// (and friends) already offer via `BranchBuild`'s autocomplete — this hits
/// the same `GET /autocomplete/branches` endpoint, just from the browser.
class BranchAutocompleteField extends ConsumerStatefulWidget {
  const BranchAutocompleteField({
    super.key,
    required this.param,
    required this.controller,
    required this.label,
    this.icon,
  });

  final ActionParam param;
  final TextEditingController controller;
  final String label;
  final IconData? icon;

  @override
  ConsumerState<BranchAutocompleteField> createState() =>
      _BranchAutocompleteFieldState();
}

class _BranchAutocompleteFieldState
    extends ConsumerState<BranchAutocompleteField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (value) async {
        try {
          return await ref.read(
            branchAutocompleteProvider((widget.param.name, value.text)).future,
          );
        } catch (_) {
          // Autocomplete is a convenience, not a requirement — the field
          // underneath still takes typed input either way.
          return const <String>[];
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            // Every one of these fields now also accepts a commit hash
            // (`sync_repo`'s fallback to a detached checkout when the value
            // isn't a branch on the remote) — the autocomplete above still
            // only ever suggests branches, so this is the only hint a typed
            // hash is just as valid as a branch name.
            hintText: 'Branch name or commit hash',
            prefixIcon: widget.icon == null ? null : Icon(widget.icon),
          ),
          validator: (value) =>
              widget.param.isRequired && (value ?? '').trim().isEmpty
              ? 'Required'
              : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final option in options)
                  ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
