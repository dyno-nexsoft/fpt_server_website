# fpt_server_website

Browser CI/CD dashboard for the `fpt_server` build orchestrator. Implements
[docs/web-ui-wireframe.md](../docs/web-ui-wireframe.md) against the REST API
described in [docs/rest-api.md](../docs/rest-api.md) — every screen maps to
an existing endpoint, no server capability is assumed.

## Run

```bash
flutter run -d chrome
```

The login screen asks for a **Server URL** (defaults to the page's own
origin) and an **API key** (`/admin api-key-add` in Discord). Both are
stored in `localStorage` — there is no server-side session.

## Configure a default server URL at build time

Useful when this app is deployed separately from the API (e.g. served
statically while the API lives on the build machine's LAN address):

```bash
flutter build web --dart-define=API_BASE_URL=http://localhost:8080
```

For local development only, `API_KEY_TEST` prefills the API key field too
(see the `fpt_server_website` launch config in the parent repo's
`.vscode/launch.json`):

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080 \
  --dart-define=API_KEY_TEST=<a disposable test key>
```

**Never commit a real key this way.** `--dart-define` values ship in the
public JS bundle of any build that used them, and a value checked into
`launch.json` sits in git history even after you change it — rotate the key
via `admin.apiKeys.remove`/`admin.apiKeys.add` instead of just editing the
file if one ever leaks there.

## Notes on individual screens

- [doc/log-viewer.md](doc/log-viewer.md) — how the build log and server log
  tail are rendered, and the append-only contract between
  `JobLogController` and `LogViewer` that keeps a streaming log cheap.
