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

- **Sync Now** always performs a full account-list pull (watchlist / rated / favorites). TMDB has no activities feed, so this is not a true incremental sync.
- After lists are fetched, Cronica fingerprints item id sets (and ratings). If the fingerprint matches the last successful sync, Core Data / catalog re-apply is skipped (cheaper; still may have downloaded pages, or reused 304 bodies).
- When TMDB returns `ETag`s, subsequent page GETs send `If-None-Match`. A `304` reuses the cached page body (bandwidth win when lists are unchanged).
- Foreground pulls are throttled (~20 minutes) after the first successful sync. When a prior fingerprint exists, Cronica first probes page 1 of each list with conditional GETs; if all are Not Modified, it skips the full pull. **Sync Now** never uses this light path.
- Optional push is **off by default**. When enabled, Cronica queues watchlist, favorite, and rating writes to TMDB.
- While either SIMKL or TMDB is applying a remote import, **both** push queues suppress enqueue (prevents cross-echo when both push toggles are on). Manual user actions still enqueue.
- Marking watched removes the title from the TMDB watchlist (TMDB has no watched-history API).
- Titles removed on TMDB stay in Cronica; nothing is auto-deleted locally. Partial import failures keep prior fingerprints and surface errors without crashing.
- No stats, playbacks, or live scrobble — those APIs do not exist for TMDB accounts.
- Disconnect clears the local session, list cache/fingerprint, and push queue (and best-effort invalidates the session on TMDB). **Delete My Data** does the same.
- Connect / push UI is available on iOS, iPadOS, macOS, and visionOS. tvOS can show status if already connected; Watch has no Integrations UI.
