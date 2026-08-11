import 'package:web/web.dart' as web;

/// Opens a URL in a new browser tab — used for "Open logs" / "Artifacts"
/// links that point at the file server, not at an in-app route.
void openInNewTab(String url) {
  web.window.open(url, '_blank');
}
