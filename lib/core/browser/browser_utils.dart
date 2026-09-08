import 'package:web/web.dart' as web;

/// Opens a URL in a new browser tab — used for "Open logs" / "Artifacts"
/// links that point at the file server, not at an in-app route.
void openInNewTab(String url) {
  web.window.open(url, '_blank');
}

/// Copies [text] to the clipboard.
///
/// Deliberately not `package:flutter/services.dart`'s `Clipboard.setData` —
/// that goes through the browser's async Clipboard API
/// (`navigator.clipboard.writeText`), which most browsers refuse outside a
/// secure context. This dashboard is served over plain HTTP on the LAN by
/// design (see docs/deployment.md — it is never published to the public
/// internet, so there is no certificate to serve HTTPS with), so that call
/// silently no-ops here: nothing throws, nothing gets copied, and whatever
/// was already on the clipboard is left untouched — which reads as "copy
/// copied the wrong thing" when it is actually "copy did nothing at all".
///
/// `document.execCommand('copy')` (via a hidden, focused, selected
/// textarea) has no such restriction and works identically over HTTP.
void copyToClipboard(String text) {
  final textarea = web.HTMLTextAreaElement()
    ..value = text
    ..style.position = 'fixed'
    ..style.opacity = '0';
  web.document.body?.appendChild(textarea);
  textarea.select();
  web.document.execCommand('copy');
  textarea.remove();
}
