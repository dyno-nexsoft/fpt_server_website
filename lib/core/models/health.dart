import 'package:freezed_annotation/freezed_annotation.dart';

part 'health.freezed.dart';
part 'health.g.dart';

/// `GET /health` — the only unauthenticated endpoint.
@freezed
abstract class Health with _$Health {
  const factory Health({
    required bool ok,
    required String version,
    required int uptimeSeconds,
    required String hostname,
  }) = _Health;

  factory Health.fromJson(Map<String, dynamic> json) => _$HealthFromJson(json);
}
