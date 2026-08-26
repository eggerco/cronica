# Security Policy

## Reporting a Vulnerability

If you discover a security issue, please email **support@cronica.watch** rather than opening a public issue.

## Secrets Management

- **Never commit API keys.** Use `Config/Secrets.xcconfig` (gitignored) for local development.
- Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig` and add your TMDb key.
- CI injects secrets via GitHub Actions repository secrets (`TMDB_API_KEY`, `SENTRY_DSN`).
- Keys are read at runtime from build settings / environment — not hardcoded in source.
- Crash reports are sent to Sentry in release builds when `SENTRY_DSN` is configured.

## Data Handling

- Watchlist data is stored locally via Core Data and synced through the user's iCloud account (CloudKit).
- TMDb API keys are sent only to `api.themoviedb.org` over HTTPS.

## Supported Platforms

Build with **Xcode 26** and the **iOS 26 SDK** for App Store submissions. Minimum deployment target: iOS 17.
