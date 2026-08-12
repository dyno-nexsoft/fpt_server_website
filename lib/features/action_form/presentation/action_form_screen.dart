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
import '../../../shared/toast/app_toast.dart';
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

  Future<void> _submit(ActionSchema action) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _problems = const [];
    });
    final body = <String, dynamic>{};
    for (final param in action.params) {
      switch (param.type) {
        case ActionParamType.enumeration:
          final value = _enumValues[param.name];
          if (value != null) body[param.name] = value;
        case ActionParamType.boolean:
          body[param.name] = _boolValues[param.name];
        case ActionParamType.integer:
          final text = _controllers[param.name]!.text.trim();
          if (text.isNotEmpty) body[param.name] = int.parse(text);
        case ActionParamType.number:
          final text = _controllers[param.name]!.text.trim();
          if (text.isNotEmpty) body[param.name] = double.parse(text);
        case ActionParamType.string:
          final text = _controllers[param.name]!.text.trim();
          if (text.isNotEmpty) body[param.name] = text;
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
      error: (error, _) => Center(child: Text('$error')),
    );
  }

  Widget _buildForm(BuildContext context, ActionSchema action) {
    final textTheme = Theme.of(context).textTheme;
    final title = action.name == 'ci.build' ? 'New build' : action.name;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(title, style: textTheme.headlineSmall),
            Text('(${action.name})', style: textTheme.bodySmall),
            const SizedBox(height: 8),
            if (action.description.isNotEmpty) Text(action.description),
            if (action.isDangerous) const _DangerCallout(),
            const SizedBox(height: 16),
            for (final param in action.params)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActionParamField(
                  param: param,
                  controller: _controllers[param.name],
                  enumValue: _enumValues[param.name],
                  boolValue: _boolValues[param.name] ?? false,
                  onEnumChanged: (value) =>
                      setState(() => _enumValues[param.name] = value),
                  onBoolChanged: (value) =>
                      setState(() => _boolValues[param.name] = value),
                ),
              ),
            if (_problems.isNotEmpty) _ProblemsCard(problems: _problems),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _submitting ? null : () => _submit(action),
              child: _submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(action.kind == ActionKind.job ? 'Start build' : 'Run'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerCallout extends StatelessWidget {
  const _DangerCallout();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.warning_amber),
        title: Text('Requires elevated permission.'),
        subtitle: Text('This action can affect the build host directly.'),
      ),
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
