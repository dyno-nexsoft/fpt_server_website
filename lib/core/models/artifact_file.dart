import 'package:freezed_annotation/freezed_annotation.dart';

import 'job.dart';

part 'artifact_file.freezed.dart';
part 'artifact_file.g.dart';

/// One entry from `GET /artifacts/{key}` — a file or subdirectory inside a
/// job's `build/<artifactKey>/` output.
@freezed
abstract class ArtifactFile with _$ArtifactFile {
  const factory ArtifactFile({
    required String name,
    @Default(false) bool isDirectory,
    int? size,
    required DateTime modified,
  }) = _ArtifactFile;

  factory ArtifactFile.fromJson(Map<String, dynamic> json) =>
      _$ArtifactFileFromJson(json);
}

/// `GET /artifacts/{key}` response: the files in that directory, plus the
/// job that produced it if one is still resolvable (see docs/rest-api.md
/// "Artifacts" — the key outlives the server's bounded job history).
@freezed
abstract class ArtifactListing with _$ArtifactListing {
  const factory ArtifactListing({
    required String key,
    @Default(<ArtifactFile>[]) List<ArtifactFile> files,
    Job? job,
  }) = _ArtifactListing;

  factory ArtifactListing.fromJson(Map<String, dynamic> json) =>
      _$ArtifactListingFromJson(json);
}
