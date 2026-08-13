import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/browser/browser_utils.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/toast/app_toast.dart';

/// Discord's `name` argument is optional (falls back to the caller's Discord
/// display name), so this is the whole command a user needs to paste — no
/// placeholder argument to fill in themselves.
const _apiKeyAddCommand = '/admin api-key-add';

/// `GET /health` is unauthenticated, so a pasted API key *is* the session —
/// see docs/web-ui-wireframe.md "Auth flow" for the full error-code table
/// this screen mirrors.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _serverController;
  late final TextEditingController _keyController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final creds = ref.read(sessionProvider);
    _serverController = TextEditingController(text: creds.serverUrl);
    _keyController = TextEditingController(text: creds.apiKey);
  }

  @override
  void dispose() {
    _serverController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _connect() {
    final serverUrl = _serverController.text.trim();
    final apiKey = _keyController.text.trim();
    if (serverUrl.isEmpty || apiKey.isEmpty) return;
    ref
        .read(connectionControllerProvider.notifier)
        .connect(serverUrl: serverUrl, apiKey: apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final connection = ref.watch(connectionControllerProvider);
    final isLoading = connection.isLoading && !connection.hasValue;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Text(
                  'CI/CD Dashboard',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall,
                ),
                const Text(
                  'A key is only needed to start, cancel, or retry a '
                  'build — browsing status, logs, and artifacts works '
                  'without one.',
                  textAlign: TextAlign.center,
                ),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      spacing: 8,
                      children: [
                        const Icon(Icons.info_outline, size: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Don't have a key?"),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(text: 'Run '),
                                    TextSpan(
                                      text: _apiKeyAddCommand,
                                      style: textTheme.bodyMedium?.merge(
                                        AppTheme.monospaceTextStyle,
                                      ),
                                    ),
                                    const TextSpan(text: ' in Discord.'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy command',
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          onPressed: () {
                            copyToClipboard(_apiKeyAddCommand);
                            ref
                                .read(appToastProvider.notifier)
                                .show('Command copied');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      TextField(
                        controller: _serverController,
                        keyboardType: TextInputType.url,
                        autofillHints: const [AutofillHints.url],
                        decoration: const InputDecoration(
                          labelText: 'Server URL',
                          hintText: 'http://localhost:8080',
                          prefixIcon: Icon(Icons.dns_outlined),
                        ),
                      ),
                      TextField(
                        controller: _keyController,
                        obscureText: _obscureKey,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'API key',
                          prefixIcon: const Icon(Icons.key_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureKey
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () =>
                                setState(() => _obscureKey = !_obscureKey),
                          ),
                        ),
                        onSubmitted: (_) => _connect(),
                      ),
                    ],
                  ),
                ),
                if (connection.hasError)
                  _ConnectError(
                    error: connection.error,
                    serverUrl: _serverController.text.trim(),
                  ),
                FilledButton(
                  onPressed: isLoading ? null : _connect,
                  child: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Connect'),
                ),
                TextButton(
                  onPressed: () => const DashboardRoute().go(context),
                  child: const Text('Continue browsing without a key'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectError extends ConsumerWidget {
  const _ConnectError({required this.error, required this.serverUrl});

  final Object? error;
  final String serverUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final err = error;
    final String message;
    final bool offerRetry;
    if (err is ApiException) {
      if (err.isUnauthorized) {
        message = 'Key not recognised.';
        offerRetry = false;
      } else if (err.isServerNotConfigured) {
        message =
            'Server has no API key configured yet. '
            'Run /admin api-key-add in Discord.';
        offerRetry = false;
      } else if (err.isNetworkError) {
        message = 'Cannot reach server at $serverUrl.';
        offerRetry = true;
      } else {
        message = err.message;
        offerRetry = false;
      }
    } else {
      message = 'Unexpected error: $err';
      offerRetry = false;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          spacing: 12,
          children: [
            const Icon(Icons.error_outline),
            Expanded(child: Text(message)),
            if (offerRetry)
              TextButton(
                onPressed: () => ref.invalidate(healthCheckProvider(serverUrl)),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
