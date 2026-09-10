import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carries a job's `actionParams` from the job detail screen to the action
/// form it reopens for "Edit & Rebuild", so the form starts from that job's
/// values instead of the schema's plain defaults. Consumed once —
/// [ActionFormControllerState.initFields] reads and clears it on the form's
/// first build.
class PendingFormSeedNotifier extends Notifier<Map<String, Object?>?> {
  @override
  Map<String, Object?>? build() => null;

  void set(Map<String, Object?> params) => state = params;

  void clear() => state = null;
}

final pendingFormSeedProvider =
    NotifierProvider<PendingFormSeedNotifier, Map<String, Object?>?>(
      PendingFormSeedNotifier.new,
    );
