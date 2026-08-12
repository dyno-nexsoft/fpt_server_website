import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/models/action_schema.dart';
import '../../../core/models/job.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/job_seed_provider.dart';
import '../../../core/providers/status_provider.dart';
import '../../../core/storage/action_template_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/toast/app_toast.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/error_view.dart';
import 'action_param_field.dart';

/// A flat form generated from `GET /actions/{name}`'s schema — one field per
/// param — so the UI can never drift from what the server actually accepts.
/// Used for `New build` (`ci.build`) and every other invokable action.
class ActionFormScreen extends ConsumerStatefulWidget {
  const ActionFormScreen({super.key, required this.actionName});

  final String actionName;

  @override
  ConsumerState<ActionFormScreen> createState() => _ActionFormScreenState();
}

class _ActionFormScreenState extends ConsumerState<ActionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _enumValues = <String, String?>{};
  final _boolValues = <String, bool>{};
  bool _initialized = false;
  bool _submitting = false;
  List<String> _problems = const [];

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initFields(ActionSchema action) {
    if (_initialized) return;
    for (final param in action.params) {
      switch (param.type) {
        case ActionParamType.enumeration:
          _enumValues[param.name] =
              param.defaultValue as String? ??
              (param.choices.isNotEmpty ? param.choices.first : null);
        case ActionParamType.boolean:
          _boolValues[param.name] = param.defaultValue as bool? ?? false;
        case ActionParamType.integer:
        case ActionParamType.number:
        case ActionParamType.string:
          _controllers[param.name] = TextEditingController(
            text: param.defaultValue?.toString() ?? '',
          );
      }
    }
    _initialized = true;
  }

  /// Reads the form's current values into a plain params map — shared by
  /// [_submit] (which sends it as the request body) and [_saveAsTemplate]
  /// (which persists it verbatim, without the int/double parsing `_submit`
  /// needs for the wire format — a template only ever feeds back into these
  /// same text fields).
  Map<String, Object?> _collectParams(ActionSchema action) {
    final params = <String, Object?>{};
    for (final param in action.params) {
      switch (param.type) {
        case ActionParamType.enumeration:
          final value = _enumValues[param.name];
          if (value != null) params[param.name] = value;
        case ActionParamType.boolean:
          params[param.name] = _boolValues[param.name];
        case ActionParamType.integer:
        case ActionParamType.number:
        case ActionParamType.string:
          final text = _controllers[param.name]!.text.trim();
          if (text.isNotEmpty) params[param.name] = text;
      }
    }
    return params;
  }

  void _applyTemplate(ActionSchema action, ActionTemplate template) {
    setState(() {
      for (final param in action.params) {
        final value = template.params[param.name];
        switch (param.type) {
          case ActionParamType.enumeration:
            if (value is String) _enumValues[param.name] = value;
          case ActionParamType.boolean:
            _boolValues[param.name] = value as bool? ?? false;
          case ActionParamType.integer:
          case ActionParamType.number:
          case ActionParamType.string:
            _controllers[param.name]!.text = value?.toString() ?? '';
        }
      }
    });
  }

  Future<void> _saveAsTemplate(ActionSchema action) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NameTemplateDialog(
        existingNames: ref
            .read(actionTemplateStoreProvider)
            .list(action.name)
            .map((t) => t.name)
            .toSet(),
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref
        .read(actionTemplateStoreProvider)
        .save(
          action.name,
          ActionTemplate(name: name, params: _collectParams(action)),
        );
    if (mounted) setState(() {});
  }

  Future<void> _deleteTemplate(ActionSchema action, String name) async {
    await ref.read(actionTemplateStoreProvider).delete(action.name, name);
    if (mounted) setState(() {});
  }

  Future<void> _submit(ActionSchema action) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _problems = const [];
    });
    final rawParams = _collectParams(action);
    final body = <String, dynamic>{};
    for (final param in action.params) {
      final value = rawParams[param.name];
      switch (param.type) {
        case ActionParamType.enumeration:
        case ActionParamType.boolean:
          if (value != null) body[param.name] = value;
        case ActionParamType.integer:
          if (value != null) body[param.name] = int.parse(value as String);
        case ActionParamType.number:
          if (value != null) body[param.name] = double.parse(value as String);
        case ActionParamType.string:
          if (value != null) body[param.name] = value;
      }
    }

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.postJson('/actions/${action.name}', body);
      ref.read(statusControllerProvider.notifier).refreshNow();
      if (action.kind == ActionKind.job) {
        final job = Job.fromJson(response);
        // GET /jobs/{id} won't carry logUrl/warnings — seed them for the
        // detail screen this navigates to next.
        ref.read(pendingJobSeedProvider.notifier).set(job);
        if (mounted) context.go('/builds/${job.id}');
        return;
      }
      final message = response['message'] as String?;
      ref
          .read(appToastProvider.notifier)
          .show(message ?? '${action.name} completed.');
    } on ApiException catch (e) {
      if (e.isValidation && e.problems != null) {
        setState(() => _problems = e.problems!);
      } else {
        ref.read(appToastProvider.notifier).show(e.message, isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionsAsync = ref.watch(actionsProvider);
    return actionsAsync.when(
      data: (actions) {
        final action = findAction(actions, widget.actionName);
        if (action == null) {
          return Center(child: Text('Unknown action ${widget.actionName}'));
        }
        _initFields(action);
        return _buildForm(context, action);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(error: error),
    );
  }

  Widget _buildForm(BuildContext context, ActionSchema action) {
    final textTheme = Theme.of(context).textTheme;
    final title = action.name == 'ci.build' ? 'New build' : action.name;
    final hasTemplates = action.params.isNotEmpty;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.headlineSmall),
        Text('(${action.name})', style: textTheme.bodySmall),
        const SizedBox(height: 8),
        if (action.description.isNotEmpty) Text(action.description),
      ],
    );

    // Not `ref.watch` — this Provider never itself changes; the list only
    // changes via `setState` after save/delete, which already forces
    // `_buildForm` to re-run.
    final templatesBar = hasTemplates
        ? _TemplatesBar(
            templates: ref.read(actionTemplateStoreProvider).list(action.name),
            onApply: (template) => _applyTemplate(action, template),
            onDelete: (name) => _deleteTemplate(action, name),
          )
        : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Side by side on desktop — matches where the template card used
            // to sit as its own full-width block below the header, which
            // pushed every field down for no benefit. Stacked on mobile:
            // there is no spare horizontal room to share.
            if (templatesBar != null && !isMobileWidth(context))
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: header),
                  const SizedBox(width: 16),
                  Expanded(child: templatesBar),
                ],
              )
            else ...[
              header,
              if (templatesBar != null) ...[
                const SizedBox(height: 16),
                templatesBar,
              ],
            ],
            const SizedBox(height: 16),
            _buildFields(action),
            if (_problems.isNotEmpty) _ProblemsCard(problems: _problems),
            const SizedBox(height: 8),
            Row(
              spacing: 12,
              children: [
                if (hasTemplates)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _saveAsTemplate(action),
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('Save current as template'),
                    ),
                  ),
                Expanded(
                  child: FilledButton(
                    style: action.isDangerous
                        ? AppTheme.destructiveButtonStyle(
                            Theme.of(context).colorScheme,
                          )
                        : null,
                    onPressed: _submitting ? null : () => _submit(action),
                    child: _submitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            action.kind == ActionKind.job
                                ? 'Start build'
                                : 'Run',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fieldWidgets(ActionSchema action) => [
    for (final param in action.params)
      ActionParamField(
        param: param,
        controller: _controllers[param.name],
        enumValue: _enumValues[param.name],
        boolValue: _boolValues[param.name] ?? false,
        onEnumChanged: (value) =>
            setState(() => _enumValues[param.name] = value),
        onBoolChanged: (value) =>
            setState(() => _boolValues[param.name] = value),
      ),
  ];

  /// A two-column grid once there are enough fields to make one worthwhile,
  /// a single full-width column otherwise — two fields spread across a
  /// SliverGridDelegateWithMaxCrossAxisExtent grid (`ci.replace`'s `url` +
  /// `tbchat`) just leaves one column stretched and the rest of the row (and
  /// most of the space below it) empty, which reads worse than the plain
  /// full-width list this is meant to improve on.
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
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 60,
        mainAxisSpacing: 12,
        crossAxisSpacing: 16,
      ),
      children: _fieldWidgets(action),
    );
  }
}

/// Saved form presets for one action — tap a chip to refill the form with
/// it. Saving a new one happens from the button next to Start build at the
/// bottom of the form, not here: this card sits beside the header, where
/// there's room for a chip list but not for a save button too.
class _TemplatesBar extends StatelessWidget {
  const _TemplatesBar({
    required this.templates,
    required this.onApply,
    required this.onDelete,
  });

  final List<ActionTemplate> templates;
  final ValueChanged<ActionTemplate> onApply;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark_border, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Templates',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            if (templates.isEmpty)
              const Text('No saved templates yet for this action.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final template in templates)
                    InputChip(
                      label: Text(template.name),
                      onPressed: () => onApply(template),
                      onDeleted: () => onDelete(template.name),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _NameTemplateDialog extends StatefulWidget {
  const _NameTemplateDialog({required this.existingNames});

  final Set<String> existingNames;

  @override
  State<_NameTemplateDialog> createState() => _NameTemplateDialogState();
}

class _NameTemplateDialogState extends State<_NameTemplateDialog> {
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

class _ProblemsCard extends StatelessWidget {
  const _ProblemsCard({required this.problems});

  final List<String> problems;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('* required (server rejected this request):'),
            for (final problem in problems) Text('• $problem'),
          ],
        ),
      ),
    );
  }
}
