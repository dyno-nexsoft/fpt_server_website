import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/job_seed_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/providers/status_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/action_template_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/toast/app_toast.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/name_template_dialog.dart';
import '../application/action_progress_source.dart';
import 'action_result_dialog.dart';
import 'submitting_indicator.dart';

/// REST response fields that carry a link worth surfacing as its own
/// button, and the label to show it under — mirrors the "View Review" /
/// "View MR" buttons `gitlab.review`/`gitlab.translateArb` already get on
/// Discord, so the website result isn't just a toast with no way to jump to
/// what was actually created.
const _resultLinkFields = {'note_url': 'View Review', 'mr_url': 'View MR'};

/// `gitlab.review`'s findings, parsed the same defensively-typed way as
/// every other field read off this external REST response — a malformed or
/// missing entry is dropped rather than thrown.
List<ReviewIssueView> _findIssues(Map<String, dynamic> response) {
  final raw = response['issues'];
  if (raw is! List) return const [];
  return [
    for (final entry in raw)
      if (entry is Map<String, dynamic> &&
          entry['severity'] is String &&
          entry['file'] is String &&
          entry['line_start'] is int &&
          entry['description'] is String)
        (
          severity: entry['severity'] as String,
          file: entry['file'] as String,
          lineStart: entry['line_start'] as int,
          lineEnd: entry['line_end'] as int?,
          description: entry['description'] as String,
          url: entry['url'] as String?,
        ),
  ];
}

/// The first recognized link field present (and non-null) in [response], if
/// any — an action's result carries at most one of these.
({String label, String url})? _findResultLink(Map<String, dynamic> response) {
  for (final entry in _resultLinkFields.entries) {
    // A type check, not a cast: this is parsing an external REST response,
    // not trusted internal state — an unexpected shape should be treated
    // as "no link" rather than throw and break the whole result handler.
    final url = response[entry.key];
    if (url is String) return (label: entry.value, url: url);
  }
  return null;
}

/// Fake "what's probably happening right now" messages shown by
/// [SubmittingIndicator] while an action's request is in flight — see that
/// widget's doc comment for why they're fake rather than real progress.
/// `gitlab.review`/`gitlab.translateArb` get AI-pipeline-specific wording
/// since they're the actions that actually run long enough for this to
/// matter; everything else gets a generic fallback.
List<String> _submittingMessages(String actionName) => switch (actionName) {
  'gitlab.review' => const [
    '🔍 Fetching the merge request\'s diffs...',
    '📄 Reading full file content for context...',
    '🤖 Asking Gemini AI to review the changes...',
    '🧠 Thinking through possible issues...',
    '📝 Compiling the review comment...',
  ],
  'gitlab.translateArb' => const [
    '📂 Reading the module\'s translation files...',
    '🔎 Finding missing translations...',
    '🤖 Asking Gemini AI to translate...',
    '🌐 Cross-checking existing locales for context...',
    '🔀 Opening the merge request...',
  ],
  _ => const [
    'Sending the request...',
    'Waiting for the server...',
    'Still working — this can take a moment...',
  ],
};

/// The shared controller layer behind every schema-generated action form:
/// owns the per-param [TextEditingController]s and enum/bool selections, the
/// template save/apply/delete flow, and the POST-on-submit logic. Both
/// `ActionFormScreen` (generic, any action) and `CiBuildFormScreen`
/// (dedicated `ci.build` layout) mix it in and supply only their own field
/// arrangement — so submission behaviour can never drift between the two.
///
/// The members are public (not `_`-private) precisely because this mixin
/// lives in its own library, separate from the two screens that use its
/// fields and call its methods — Dart privacy is per-library, so a private
/// member here would be unreachable from those screens.
mixin ActionFormControllerState<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  final formKey = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final enumValues = <String, String?>{};
  final boolValues = <String, bool>{};
  bool _initialized = false;
  bool submitting = false;
  List<String> problems = const [];

  /// Live server-reported progress for the call currently in flight, for any
  /// action whose schema sets `supportsProgress`. Null while idle, and for
  /// an action that reports nothing — [SubmittingIndicator] falls back to
  /// its canned messages then.
  ActionProgressSource? progressSource;

  /// The last result [ActionResultDialog] was (or would have been) built
  /// from — kept so "View last result" can reopen it after an accidental
  /// dismiss, without re-running the action just to see it again. Mirrored
  /// to [LastResultStore] on every change and restored from there in
  /// [initFields], so a page refresh doesn't lose it either.
  ActionResultView? lastResult;

  /// The template currently filled into the form, if any — highlighted in
  /// [_TemplatesBar] and used to pre-fill [saveAsTemplate]'s dialog so
  /// saving over it doesn't require retyping its name.
  String? selectedTemplateName;

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void initFields(ActionSchema action) {
    if (_initialized) return;
    for (final param in action.params) {
      switch (param.type) {
        case ParamType.enumeration:
          enumValues[param.name] =
              param.defaultValue as String? ??
              (param.choices.isNotEmpty ? param.choices.first : null);
        case ParamType.boolean:
          boolValues[param.name] = param.defaultValue as bool? ?? false;
        case ParamType.integer:
        case ParamType.number:
        case ParamType.string:
          controllers[param.name] = TextEditingController(
            text: _defaultFieldText(param.defaultValue),
          );
      }
    }
    lastResult = ref.read(lastResultStoreProvider).load(action.name);
    _initialized = true;
  }

  /// A param's default/template value rendered into a text field — joined
  /// with `\n` when it's a [List] (an [ActionParam.isStringList] field's
  /// wire value), since that's what [collectParams] later splits back on.
  String _defaultFieldText(Object? value) =>
      value is List ? value.join('\n') : value?.toString() ?? '';

  /// Reads the form's current values into a plain params map — shared by
  /// [submit] (which sends it as the request body) and [saveAsTemplate]
  /// (which persists it verbatim, without the int/double parsing [submit]
  /// needs for the wire format — a template only ever feeds back into these
  /// same text fields).
  Map<String, Object?> collectParams(ActionSchema action) {
    final params = <String, Object?>{};
    for (final param in action.params) {
      switch (param.type) {
        case ParamType.enumeration:
          final value = enumValues[param.name];
          if (value != null) params[param.name] = value;
        case ParamType.boolean:
          params[param.name] = boolValues[param.name];
        case ParamType.integer:
        case ParamType.number:
          final text = controllers[param.name]!.text.trim();
          if (text.isNotEmpty) params[param.name] = text;
        case ParamType.string:
          final text = controllers[param.name]!.text.trim();
          if (param.isStringList) {
            final entries = text
                .split('\n')
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .toList();
            if (entries.isNotEmpty) params[param.name] = entries;
          } else if (text.isNotEmpty) {
            params[param.name] = text;
          }
      }
    }
    return params;
  }

  void applyTemplate(ActionSchema action, ActionTemplate template) {
    setState(() {
      for (final param in action.params) {
        final value = template.params[param.name];
        switch (param.type) {
          case ParamType.enumeration:
            if (value is String) enumValues[param.name] = value;
          case ParamType.boolean:
            boolValues[param.name] = value as bool? ?? false;
          case ParamType.integer:
          case ParamType.number:
          case ParamType.string:
            controllers[param.name]!.text = _defaultFieldText(value);
        }
      }
      selectedTemplateName = template.name;
    });
  }

  Future<void> saveAsTemplate(ActionSchema action) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => NameTemplateDialog(
        initialName: selectedTemplateName,
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
          ActionTemplate(name: name, params: collectParams(action)),
        );
    if (mounted) setState(() => selectedTemplateName = name);
  }

  Future<void> deleteTemplate(ActionSchema action, String name) async {
    await ref.read(actionTemplateStoreProvider).delete(action.name, name);
    if (mounted) {
      setState(() {
        if (selectedTemplateName == name) selectedTemplateName = null;
      });
    }
  }

  Future<void> submit(ActionSchema action) async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    // Opened before the request goes out, not after: the feed is addressed
    // by an id this client invents, so there is nothing to subscribe to
    // until it does — and a step reported early would otherwise be missed.
    final invocationId = action.supportsProgress
        ? ActionProgressSource.generateId()
        : null;
    final progress = invocationId == null
        ? null
        : (ActionProgressSource()..connect(
            baseUrl: ref.read(sessionProvider).normalizedServerUrl,
            invocationId: invocationId,
          ));

    var showDialogAfterwards = false;
    setState(() {
      submitting = true;
      problems = const [];
      progressSource = progress;
    });
    // Inside the try, not before it: `submitting` is already true and the
    // progress stream already open by this point, so a throw out here (an
    // `int.parse` on a field the validator somehow let through) would strand
    // the form disabled forever and leak the EventSource.
    try {
      final rawParams = collectParams(action);
      final body = <String, dynamic>{};
      for (final param in action.params) {
        final value = rawParams[param.name];
        switch (param.type) {
          case ParamType.enumeration:
          case ParamType.boolean:
            if (value != null) body[param.name] = value;
          case ParamType.integer:
            if (value != null) body[param.name] = int.parse(value as String);
          case ParamType.number:
            if (value != null) body[param.name] = double.parse(value as String);
          case ParamType.string:
            if (value != null) body[param.name] = value;
        }
      }

      final api = ref.read(apiClientProvider);
      final response = await api.decodeMap(
        api.endpoints.invokeAction(
          action.name,
          api.encodeBody(body),
          invocationId: invocationId,
        ),
      );
      ref.read(statusControllerProvider.notifier).refreshNow();
      if (action.kind == ActionKind.job) {
        final job = Job.fromJson(response);
        // GET /jobs/{id} won't carry logUrl/warnings — seed them for the
        // detail screen this navigates to next.
        ref.read(pendingJobSeedProvider.notifier).set(job);
        if (mounted) JobDetailRoute(job.id).go(context);
        return;
      }
      // Type checks, not casts, throughout this block: an external REST
      // response with an unexpected shape should degrade (fall back to a
      // default, drop a bad entry) rather than throw and turn a
      // successful action into an unhandled exception.
      final rawMessage = response['message'];
      final message = rawMessage is String
          ? rawMessage
          : '${action.name} completed.';
      final link = _findResultLink(response);
      final warnings =
          (response['warnings'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [];
      final keysByFile =
          (response['keys_by_file'] as Map<String, dynamic>?) ?? const {};
      final details = [
        for (final entry in keysByFile.entries)
          '${entry.key}: ${entry.value} key(s)',
      ];
      final issues = _findIssues(response);
      final result = (
        message: message,
        details: details,
        warnings: warnings,
        issues: issues,
        link: link,
      );
      await ref.read(lastResultStoreProvider).save(action.name, result);
      if (mounted) setState(() => lastResult = result);
      // Recorded, not shown, here: the dialog is opened after `finally` has
      // run. Awaiting it inside the try held the whole cleanup hostage to
      // the user dismissing it — the submit button stayed disabled and still
      // spinning on the last progress line, "View last result" stayed
      // hidden, and the EventSource stayed connected the entire time the
      // dialog was on screen.
      showDialogAfterwards =
          link != null ||
          warnings.isNotEmpty ||
          details.isNotEmpty ||
          issues.isNotEmpty;
      if (!showDialogAfterwards) {
        ref.read(appToastProvider.notifier).show(message);
      }
    } on ApiException catch (e) {
      if (e.isValidation && e.problems != null) {
        setState(() => problems = e.problems!);
      } else {
        ref.read(appToastProvider.notifier).show(e.message, isError: true);
      }
    } finally {
      // The server closes its side once the invocation ends; closing here
      // too releases the browser's EventSource rather than leaving it
      // retrying a feed that will never speak again.
      progress?.close();
      if (mounted) {
        setState(() {
          submitting = false;
          progressSource = null;
        });
      }
    }

    if (showDialogAfterwards && mounted) await showResultDialog();
  }

  /// Opens [ActionResultDialog] for [lastResult] — called right after a
  /// submit that has something worth it, and again by "View last result"
  /// if the dialog gets dismissed and the user wants it back without
  /// re-running the action.
  Future<void> showResultDialog() async {
    final result = lastResult;
    if (result == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => ActionResultDialog(
        message: result.message,
        details: result.details,
        warnings: result.warnings,
        issues: result.issues,
        link: result.link,
      ),
    );
  }

  /// The async-loading scaffold every action form shares: watches the action
  /// catalogue, resolves the action by name, seeds the fields once, then
  /// renders `formBuilder` — with the same loading/error/unknown-action
  /// states regardless of which screen mixed this controller in.
  Widget buildActionForm(
    BuildContext context,
    String actionName,
    Widget Function(ActionSchema action) formBuilder,
  ) {
    final actionsAsync = ref.watch(actionsProvider);
    return actionsAsync.when(
      data: (actions) {
        final action = findAction(actions, actionName);
        if (action == null) {
          return Center(child: Text('Unknown action $actionName'));
        }
        initFields(action);
        return formBuilder(action);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(error: error),
    );
  }

  /// The shared form chrome both the generic and dedicated forms reuse: the
  /// header, the [_TemplatesBar] (with its save button), the problem card, and
  /// the submit button — wrapped in the [Form] and the scrolling [ListView].
  /// Only `fields` differs between forms, so the layout and behaviour around
  /// it can never drift.
  Widget buildFormScaffold(
    BuildContext context,
    ActionSchema action, {
    required String title,
    required Widget fields,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(title, style: textTheme.headlineSmall),
        Text('(${action.name})', style: textTheme.bodySmall),
        if (action.description.isNotEmpty) Text(action.description),
      ],
    );

    // Not `ref.watch` — this Provider never itself changes; the list only
    // changes via `setState` after save/delete, which already forces
    // `buildFormScaffold` to re-run.
    final hasTemplates = action.params.isNotEmpty;
    final templatesBar = hasTemplates
        ? _TemplatesBar(
            templates: ref.read(actionTemplateStoreProvider).list(action.name),
            selectedName: selectedTemplateName,
            onApply: (template) => applyTemplate(action, template),
            onDelete: (name) => deleteTemplate(action, name),
            onSave: () => saveAsTemplate(action),
          )
        : null;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (templatesBar != null && !isMobileWidth(context))
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Expanded(child: header),
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
          const SizedBox(height: 24),
          fields,
          if (problems.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ProblemsCard(problems: problems),
          ],
          const SizedBox(height: 8),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: FilledButton(
                  style: action.isDangerous
                      ? AppTheme.destructiveButtonStyle(theme.colorScheme)
                      : null,
                  onPressed: submitting ? null : () => submit(action),
                  child: submitting
                      ? SubmittingIndicator(
                          messages: _submittingMessages(action.name),
                          liveStatus: progressSource?.status,
                        )
                      : Text(
                          action.kind == ActionKind.job ? 'Start build' : 'Run',
                        ),
                ),
              ),
              if (lastResult != null && !submitting)
                OutlinedButton(
                  onPressed: showResultDialog,
                  child: const Text('View last result'),
                ),
            ],
          ),
        ],
      ),
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
    required this.selectedName,
    required this.onApply,
    required this.onDelete,
    this.onSave,
  });

  final List<ActionTemplate> templates;

  /// The template currently filled into the form, if any — shown with a
  /// checkmark so "Save current as template" has an obvious target.
  final String? selectedName;
  final ValueChanged<ActionTemplate> onApply;
  final ValueChanged<String> onDelete;

  /// Saves the current form values as a new template. Optional because the
  /// generic form keeps that button at the bottom next to submit, while the
  /// dedicated forms hoist it up into this card's header — passing it here
  /// renders a bookmark-plus icon in the header row.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                const Icon(Icons.bookmark_border),
                Expanded(
                  child: Text('Templates', style: theme.textTheme.labelLarge),
                ),
                if (onSave != null)
                  IconButton.outlined(
                    onPressed: onSave,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    tooltip: 'Save current as template',
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
                      selected: template.name == selectedName,
                      showCheckmark: true,
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
