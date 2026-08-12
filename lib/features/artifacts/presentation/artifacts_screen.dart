import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/browser/browser_utils.dart';
import '../../../core/models/artifact_file.dart';
import '../../../core/providers/session_provider.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/artifacts_provider.dart';

/// Browses one job's output directory (`build/<artifactKey>/`).
///
/// Replaces the server-rendered directory listing the file server used to
/// return for `/<artifactKey>/` — that path now redirects here. Reached
/// both that way (old Discord links) and from a job's "Artifacts" button.
class ArtifactsScreen extends ConsumerWidget {
  const ArtifactsScreen({super.key, required this.artifactKey});

  final String artifactKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final listing = ref.watch(artifactListingProvider(artifactKey));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            children: [
              Text('Artifacts', style: textTheme.headlineSmall),
              const SizedBox(width: 12),
              Text(artifactKey, style: textTheme.bodySmall),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    ref.invalidate(artifactListingProvider(artifactKey)),
              ),
            ],
          ),
          Expanded(
            child: listing.when(
              data: (data) => _ArtifactList(listing: data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  error is ApiException && error.statusCode == 404
                  ? const Center(child: _ArtifactsGone())
                  : ErrorView(error: error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when `GET /artifacts/{key}` 404s — the job record can outlive its
/// files: `assets/clean.sh` prunes `build/<artifactKey>/` by age on its own
/// schedule, independent of how long the job stays in history, so this is an
/// expected, recoverable state rather than an error to surface raw.
class _ArtifactsGone extends StatelessWidget {
  const _ArtifactsGone();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        const Icon(Icons.folder_off_outlined, size: 48),
        Text('These artifacts are gone', style: textTheme.titleMedium),
        Text(
          'Cleaned up by disk housekeeping — the build record is still '
          'kept, but its files are no longer on disk.',
          style: textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        TextButton.icon(
          onPressed: () => context.go('/builds'),
          icon: const Icon(Icons.list_alt_outlined),
          label: const Text('Back to Builds'),
        ),
      ],
    );
  }
}

class _ArtifactList extends ConsumerWidget {
  const _ArtifactList({required this.listing});

  final ArtifactListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final origin = Uri.parse(
      ref.watch(sessionProvider).normalizedServerUrl,
    ).origin;

    return ListView(
      children: [
        if (listing.job case final job?)
          Card(
            child: ListTile(
              leading: const Icon(Icons.precision_manufacturing_outlined),
              title: Text(job.actionName ?? job.command),
              subtitle: Text('Job ${job.id}'),
              trailing: FilledButton.tonal(
                onPressed: () => context.go('/builds/${job.id}'),
                child: const Text('Open build'),
              ),
            ),
          ),
        if (listing.files.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('This directory is empty.'),
            ),
          ),
        for (final file in listing.files)
          _ArtifactTile(file: file, listingKey: listing.key, origin: origin),
      ],
    );
  }
}

class _ArtifactTile extends StatelessWidget {
  const _ArtifactTile({
    required this.file,
    required this.listingKey,
    required this.origin,
  });

  final ArtifactFile file;
  final String listingKey;
  final String origin;

  String get _url => '$origin/$listingKey/${Uri.encodeComponent(file.name)}';

  bool get _isIpa => file.name.toLowerCase().endsWith('.ipa');

  /// Apple's over-the-air install handoff: the device fetches a manifest
  /// (served by `ftp_handler`'s `manifest.plist?ipa=` route) which points back
  /// at the `.ipa`. Requires an iOS device *and* HTTPS — the server is
  /// LAN-only now, so this only works over a VPN/tunnel that terminates TLS
  /// in front of it; a bare `http://` [origin] will not trigger the install.
  String get _installUrl {
    final ipaPath = Uri.encodeComponent('$listingKey/${file.name}');
    final manifestUrl = '$origin/manifest.plist?ipa=$ipaPath';
    return 'itms-services://?action=download-manifest'
        '&url=${Uri.encodeComponent(manifestUrl)}';
  }

  @override
  Widget build(BuildContext context) {
    final size = file.size;
    return ListTile(
      leading: Icon(
        file.isDirectory
            ? Icons.folder_outlined
            : Icons.insert_drive_file_outlined,
      ),
      title: Text(file.name),
      subtitle: Text(
        '${size == null ? '—' : formatFileSize(size)} · '
        '${formatRelativeTimestamp(file.modified)}',
      ),
      trailing: file.isDirectory
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isIpa)
                  IconButton(
                    tooltip: 'Install on iOS',
                    icon: const Icon(Icons.install_mobile),
                    onPressed: () => openInNewTab(_installUrl),
                  ),
                IconButton(
                  tooltip: 'View raw',
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => openInNewTab('$_url?raw=1'),
                ),
                IconButton(
                  tooltip: 'Download',
                  icon: const Icon(Icons.download_outlined),
                  onPressed: () => openInNewTab(_url),
                ),
              ],
            ),
    );
  }
}
