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

## TMDB

Optional account bridge for personal watchlist, ratings, and favorites. Catalog browsing still uses the app TMDb API key.

1. Ensure `TMDB_API_KEY` is set in `Config/Secrets.xcconfig`.
2. In the app: **Settings → Integrations → TMDB**.
3. Sign in via TMDB’s browser approve flow (`cronica://tmdb/callback`).

Behavior notes:

- **Sync Now** re-downloads account lists (watchlist / rated / favorites). TMDB has no activities feed, so there is no true incremental sync.
- Foreground pulls are throttled (~20 minutes) after the first successful sync.
- Optional push is **off by default**. When enabled, Cronica queues watchlist, favorite, and rating writes to TMDB.
- Marking watched removes the title from the TMDB watchlist (TMDB has no watched-history API).
- Titles removed on TMDB stay in Cronica; nothing is auto-deleted locally.
- No stats, playbacks, or live scrobble — those APIs do not exist for TMDB accounts.
- Disconnect clears the local session (and best-effort invalidates it on TMDB). **Delete My Data** also clears the session and push queue.
- Connect / push UI is available on iOS, iPadOS, macOS, and visionOS. tvOS can show status if already connected; Watch has no Integrations UI.
