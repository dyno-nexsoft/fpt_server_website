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

## Notes on individual screens

- [doc/log-viewer.md](doc/log-viewer.md) — how the build log and server log
  tail are rendered, and the append-only contract between
  `JobLogController` and `LogViewer` that keeps a streaming log cheap.
