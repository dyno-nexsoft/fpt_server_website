import 'job.dart';

/// One entry from `GET /artifacts/{key}` — a file or subdirectory inside a
/// job's `build/<artifactKey>/` output.
class ArtifactFile {
  const ArtifactFile({
    required this.name,
    required this.isDirectory,
    this.size,
    required this.modified,
  });

  factory ArtifactFile.fromJson(Map<String, dynamic> json) => ArtifactFile(
    name: json['name'] as String,
    isDirectory: json['is_directory'] as bool? ?? false,
    size: json['size'] as int?,
    modified: DateTime.parse(json['modified'] as String),
  );

  final String name;
  final bool isDirectory;
  final int? size;
  final DateTime modified;
}

/// `GET /artifacts/{key}` response: the files in that directory, plus the
/// job that produced it if one is still resolvable (see docs/rest-api.md
/// "Artifacts" — the key outlives the server's bounded job history).
class ArtifactListing {
  const ArtifactListing({required this.key, required this.files, this.job});

  factory ArtifactListing.fromJson(Map<String, dynamic> json) =>
      ArtifactListing(
        key: json['key'] as String,
        files: (json['files'] as List<dynamic>? ?? [])
            .map((e) => ArtifactFile.fromJson(e as Map<String, dynamic>))
            .toList(),
        job: json['job'] != null
            ? Job.fromJson(json['job'] as Map<String, dynamic>)
            : null,
      );

  final String key;
  final List<ArtifactFile> files;
  final Job? job;
}
