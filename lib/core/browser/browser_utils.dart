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
/// secure context. This dashboard is served over HTTPS with a self-signed
/// certificate the bot generates on first boot (`FtpServer._ensureCertificate`,
/// never a CA-trusted one — see docs/deployment.md), and browsers are
/// inconsistent about treating that as "secure" for API purposes even after a
/// visitor clicks through the certificate warning. Rather than depend on that,
/// this call silently no-ops when it is refused: nothing throws, nothing gets
/// copied, and whatever was already on the clipboard is left untouched —
/// which reads as "copy copied the wrong thing" when it is actually "copy did
/// nothing at all".
///
/// `document.execCommand('copy')` (via a hidden, focused, selected
/// textarea) has no such restriction and works regardless of certificate
/// trust.
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
