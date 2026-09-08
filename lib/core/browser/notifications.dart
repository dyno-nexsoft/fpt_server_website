import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Desktop notifications via the browser's own Notification API.
///
/// "Local" in the literal sense: nothing here survives a closed tab or a
/// reload. A real push notification needs a service worker and a server
/// that can wake one up while the tab is gone entirely — a different,
/// considerably larger feature this deliberately isn't. This only ever
/// fires while the tab is already open and already watching something
/// worth notifying about (a job's SSE stream, say), which every current
/// call site already is.
class BrowserNotifications {
  const BrowserNotifications();

  /// False for a browser (or embedded webview) that strips the Notification
  /// API entirely — checked via `globalContext.has`, since touching
  /// `web.Notification.permission` directly on one throws a
  /// `ReferenceError` rather than returning something falsy.
  bool get isSupported => globalContext.has('Notification');

  /// `'granted'`, `'denied'`, or `'default'` (not yet asked).
  /// [isSupported] false reads as `'denied'`, so a caller can treat both the
  /// same way without checking it separately.
  String get permission => isSupported ? web.Notification.permission : 'denied';

  /// Asks the user, if they haven't already answered this origin.
  ///
  /// Must be called from a user gesture (a button press) — most browsers
  /// silently ignore the prompt otherwise, so this is only ever wired to a
  /// Settings toggle, never fired automatically on page load.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    final result = await web.Notification.requestPermission().toDart;
    return result.toDart == 'granted';
  }

  /// Shows a notification — but only when it would actually add
  /// information: permission must already be granted, and this tab must be
  /// the one in the background. A visible tab already has the in-app toast
  /// or dialog for the same event; a notification on top of that would be a
  /// duplicate, not a notification.
  void show(String title, {String? body}) {
    if (permission != 'granted') return;
    if (!web.document.hidden) return;
    web.Notification(title, web.NotificationOptions(body: body ?? ''));
  }
}
