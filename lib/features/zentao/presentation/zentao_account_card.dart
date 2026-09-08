import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../application/zentao_controller.dart';

/// `zentao.link` / `zentao.unlink` — which Zentao account this Discord
/// account acts as.
class ZentaoAccountCard extends ConsumerWidget {
  const ZentaoAccountCard({super.key, required this.status});

  final ZentaoStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!status.linked) {
      return const Card(
        child: ExpansionTile(
          leading: Icon(Icons.link_off),
          title: Text('Not linked'),
          subtitle: Text('Link a Zentao account to file daily reports'),
          children: [_LinkForm()],
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.link),
        title: Text(status.account ?? 'Linked'),
        subtitle: const Text('Linked Zentao account'),
        trailing: FilledButton.tonalIcon(
          onPressed: () => _confirmUnlink(context, ref),
          icon: const Icon(Icons.link_off),
          label: const Text('Unlink'),
        ),
      ),
    );
  }

  Future<void> _confirmUnlink(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Zentao account?'),
        content: const Text(
          'Daily reports stop working until an account is linked again. '
          'Existing tasks in Zentao are untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(zentaoControllerProvider).unlink();
  }
}

/// Stateful for the obscured password field, which is the whole reason
/// `zentao.link` is kept out of the dashboard's generic action form: that
/// form renders every string param as plain visible text.
class _LinkForm extends ConsumerStatefulWidget {
  const _LinkForm();

  @override
  ConsumerState<_LinkForm> createState() => _LinkFormState();
}

class _LinkFormState extends ConsumerState<_LinkForm> {
  final _account = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          TextField(
            controller: _account,
            decoration: const InputDecoration(labelText: 'Zentao account'),
            autofillHints: const [AutofillHints.username],
          ),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Zentao password'),
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
          ),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: const Icon(Icons.link),
            label: const Text('Link account'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final account = _account.text.trim();
    final password = _password.text;
    if (account.isEmpty || password.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(zentaoControllerProvider)
          .link(account: account, password: password);
      // Cleared whether or not the link succeeded: on success the card
      // rebuilds into its linked state and this form is gone, and on failure
      // a stale password sitting in a field is worth less than not leaving
      // one there.
      _password.clear();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
