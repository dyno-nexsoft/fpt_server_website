import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';

/// Carries a just-created [Job] (with the creation-response-only `logUrl`/
/// `warnings`) from the action form to the job detail screen it navigates
/// to next, since a subsequent `GET /jobs/{id}` won't return those fields.
/// [JobLogController] reads and clears this once on startup.
class PendingJobSeedNotifier extends Notifier<Job?> {
  @override
  Job? build() => null;

  void set(Job job) => state = job;

  void clear() => state = null;
}

final pendingJobSeedProvider = NotifierProvider<PendingJobSeedNotifier, Job?>(
  PendingJobSeedNotifier.new,
);
