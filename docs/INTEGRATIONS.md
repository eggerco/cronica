# Integrations

Cronica’s primary catalog and sync path is **TMDb + iCloud (CloudKit)**. Third-party services are optional and only contacted when you connect or import.

## SIMKL

Optional library bridge for movies, TV, and anime.

1. Create a SIMKL API app and set the OAuth redirect URI to `cronica://simkl/callback`.
2. Copy `Config/Secrets.xcconfig.example` → `Config/Secrets.xcconfig` and set `SIMKL_CLIENT_ID`.
3. In the app: **Settings → Integrations → SIMKL**.

Behavior notes:

- Import pulls SIMKL → Cronica; optional push of watches is **off by default**.
- Foreground activity checks are throttled (~20 minutes). Manual **Sync Now** always runs.
- Titles removed on SIMKL are counted but **never auto-deleted** from Cronica.
- Stats and paused playbacks load only when you tap the buttons (expensive SIMKL endpoints).
- Live player scrobbling is not used (Cronica has no full media player).

## TMDB Account

Optional sign-in to import personal TMDB lists. Catalog browsing still uses the app TMDb API key.
