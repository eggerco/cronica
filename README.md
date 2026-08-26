<p align="center">
  <img src="web/public/assets/icon.png" alt="Cronica" width="128" height="128" />
</p>

<h1 align="center">Cronica</h1>

<p align="center">
  Track what you watch. Never lose your place.<br />
  A SwiftUI watchlist for movies and TV — with release reminders and iCloud sync across Apple devices.
</p>

<p align="center">
  <a href="https://apps.apple.com/app/cronica/id1614950275">
    <img src="web/public/assets/download.svg" alt="Download on the App Store" width="160" />
  </a>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/eggerco/cronica?style=flat-square" alt="MIT License" /></a>
  <img src="https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift" />
  <img src="https://img.shields.io/badge/platforms-iOS%20%7C%20iPadOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20visionOS-lightgrey?style=flat-square" alt="Platforms" />
</p>

<p align="center">
  <a href="https://www.cronica.watch">Website</a> ·
  <a href="https://www.cronica.watch/privacy">Privacy</a> ·
  <a href="https://x.com/CronicaApp">X</a> ·
  <a href="mailto:support@cronica.watch">Support</a>
</p>

---

## Features

- **Watchlist** — Save movies and shows; organize with lists, favorites, pins, and archives
- **Episode tracking** — Mark what you’ve watched and pick up where you left off
- **Release reminders** — Local notifications for new episodes and movie releases
- **iCloud sync** — Core Data + CloudKit keeps your list in sync across devices
- **Discover** — Explore, search, and browse with TMDb data
- **Everywhere Apple** — iPhone, iPad, Mac, Apple Watch, Apple TV, and Vision Pro

## Requirements

| | |
|---|---|
| **Xcode** | 26+ (iOS 26 SDK for App Store submissions) |
| **Deployment** | iOS / iPadOS / tvOS 17+, watchOS 10+, macOS 14+, visionOS 1+ |
| **Accounts** | [TMDb API](https://www.themoviedb.org/documentation/api) key (required to build) |

## Getting started

1. Install [Xcode 26](https://developer.apple.com/xcode/) or later.
2. Clone this repository and open `Cronica.xcodeproj`.
3. Copy `Config/Secrets.xcconfig.example` → `Config/Secrets.xcconfig`.
4. Add your TMDb API key (and optionally `SENTRY_DSN`, `SIMKL_CLIENT_ID`) in `Secrets.xcconfig`.
5. Build the **Cronica (EN-US)** scheme.

For CI, set repository secrets `TMDB_API_KEY` and optionally `SENTRY_DSN`. See [SECURITY.md](SECURITY.md). Optional integrations (SIMKL and others): [Docs/INTEGRATIONS.md](Docs/INTEGRATIONS.md).

## Architecture

```
Cronica/
├── Shared/                 # SwiftUI app (iOS, iPadOS, macOS, tvOS, visionOS)
├── AppleWatch/             # Watch-specific UI
├── CronicaWidget/          # Widgets
├── Packages/CronicaCore/   # Shared models & TMDb networking
├── web/                    # Marketing site (Cloudflare Worker) → www.cronica.watch
└── Config/                 # Secrets.xcconfig (gitignored) + example
```

- **Persistence** — Core Data (`NSPersistentCloudKitContainer`); syncs when the user is signed into iCloud
- **Networking** — TMDb via `CronicaCore`
- **Notifications** — Local notifications + background refresh for upcoming releases

## Contributing

Issues and pull requests are welcome.

**Translations** — Edit [`Shared/Localization/Localizable.xcstrings`](Shared/Localization/Localizable.xcstrings) and open a PR, or email completed strings to [support@cronica.watch](mailto:support@cronica.watch).

Before a release, run through [`Docs/QA-SMOKE-TEST.md`](Docs/QA-SMOKE-TEST.md).

## Security & privacy

- Never commit API keys — use `Config/Secrets.xcconfig` (see [SECURITY.md](SECURITY.md))
- Privacy policy: [www.cronica.watch/privacy](https://www.cronica.watch/privacy)
- Report vulnerabilities privately to [support@cronica.watch](mailto:support@cronica.watch)

## Acknowledgments

Movie and TV data from [TMDb](https://www.themoviedb.org). This product uses the TMDb API but is not endorsed or certified by TMDb.

## License

Cronica is released under the [MIT License](LICENSE) — copyright © 2022–2026 [Egger & Co](https://eggerco.com).

```
SPDX-License-Identifier: MIT
```
