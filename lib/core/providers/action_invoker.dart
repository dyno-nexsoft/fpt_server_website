import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/toast/app_toast.dart';
import '../api/api_exception.dart';
import 'core_providers.dart';

/// Invokes a REST action by name and surfaces any failure via the global
/// toast — the `try { invoke } on ApiException { toast }` sequence that used
/// to be duplicated across every settings tile.
///
/// Lives in `core/` rather than under one feature: it started as the settings
/// screen's `AdminActionsController`, but nothing about it was ever
/// admin-specific, and the Zentao screen invoking plain `invoke`-level
/// actions through something named "admin" would have read as a permission
/// claim it does not make.
class ActionInvoker {
  ActionInvoker(this._ref);

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

final actionInvokerProvider = Provider<ActionInvoker>(ActionInvoker.new);
