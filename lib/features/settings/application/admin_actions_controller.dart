import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../shared/toast/app_toast.dart';

/// Invokes an admin REST action by name and surfaces any failure via the
/// global toast — the `try { invoke } on ApiException { toast }` sequence
/// that used to be duplicated across every admin settings tile (system
/// actions, API key management, Hive box maintenance).
class AdminActionsController {
  AdminActionsController(this._ref);

  final Ref _ref;

  /// Invokes [actionName] with [params] and returns the decoded response, or
  /// `null` after showing the error toast itself — callers only need to
  /// handle the success path.
  Future<Map<String, dynamic>?> run(
    String actionName,
    Map<String, dynamic> params,
  ) async {
    try {
      final api = _ref.read(apiClientProvider);
      return await api.decodeMap(
        api.endpoints.invokeAction(actionName, api.encodeBody(params)),
      );
    } on ApiException catch (e) {
      _ref.read(appToastProvider.notifier).show(e.message, isError: true);
      return null;
    }
  }
}

final adminActionsControllerProvider = Provider<AdminActionsController>(
  AdminActionsController.new,
);
