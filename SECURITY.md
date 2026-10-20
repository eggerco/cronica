# Security Policy

## Reporting a Vulnerability

If you discover a security issue, please email **support@cronica.watch** rather than opening a public issue.

## Secrets Management

- **Never commit API keys.** Use `Config/Secrets.xcconfig` (gitignored) for local development.
- Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig` and add your TMDb key.
- CI injects `TMDB_API_KEY` only on `push` to `main` (never into `pull_request` jobs, so PR checkouts cannot read repository secrets via the process environment).
- `SENTRY_DSN` is not injected in CI; Release builds load it from `Secrets.xcconfig` / Info.plist only.
- Keys are read at runtime from build settings / environment — not hardcoded in source.
- Crash reports are sent to Sentry in release builds when `SENTRY_DSN` is configured; query parameters such as `session_id` and `api_key` are scrubbed before events leave the device.

## Data Handling

- Watchlist data is stored locally via Core Data and synced through the user's iCloud account (CloudKit).
- TMDb API keys are sent only to `api.themoviedb.org` over HTTPS.

## Supported Platforms

Build with **Xcode 26** and the **iOS 26 SDK** for App Store submissions. Minimum deployment target: iOS 17.
