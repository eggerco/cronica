# Siri & Shortcuts

Cronica uses **App Intents** (iOS 17+) for Siri and the Shortcuts app on **iPhone, iPad, Mac, and Vision Pro**. watchOS and tvOS do not include these intents.

## Voice commands

| Say | Action |
|-----|--------|
| “Add *Dune* to Cronica” | Search TMDb → add to watchlist |
| “Remove *Severance* from my watchlist” | Remove from local watchlist |
| “Mark *Oppenheimer* as watched” | Mark watched (auto-adds if needed) |
| “Mark my next episode as watched” | Mark current Up Next episode |
| “What’s up next on Cronica?” | Read Up Next queue |
| “Open search in Cronica” | Open Search tab |
| “Add this link to Cronica” | Add from shared URL (Shortcuts / Siri) |
| “Open *The Bear* in Cronica” | Deep-link into title details |

## In-app setup

**Settings → Siri & Shortcuts** lists example phrases and opens the Shortcuts gallery via `ShortcutsLink`.

On first use, enable Cronica under **Settings → Siri & Search** on device.

## Architecture

| File | Role |
|------|------|
| `Shared/Intents/SiriIntentService.swift` | Business logic (watchlist, TMDb, Up Next) |
| `Shared/Intents/CronicaAppIntents.swift` | Intent definitions |
| `Shared/Intents/CronicaAppEntities.swift` | Siri entity queries (watchlist, search) |
| `Shared/Intents/CronicaAppShortcuts.swift` | App Shortcuts provider (8 shortcuts) |
| `Shared/Intents/SiriNavigationBridge.swift` | Pending deep links + open-search flag |
| `Shared/Intents/SiriShortcutRefreshBridge.swift` | Calls `updateAppShortcutParameters()` |
| `Shared/Intents/SiriIntentDonation.swift` | Donates intents after in-app actions |

### Shortcut parameter refresh

When the watchlist changes (add, remove, mark watched, episode progress), the app calls:

```swift
CronicaAppShortcuts.updateAppShortcutParameters()
```

via `SiriShortcutRefreshBridge`. This keeps parameterized phrases (e.g. “Remove *Severance* from Cronica”) in sync with your library.

The app also refreshes shortcut parameters on **launch**.

### Intent donation

After adding or marking watched in the app, Cronica donates matching intents so Siri can surface better suggestions over time.

## Testing (physical device required)

Siri does not fully work in Simulator. Use a real iPhone:

1. Build & run a Debug or TestFlight build.
2. **Settings → Siri & Search → Cronica** → enable Learn from this App / Show App in Search.
3. Try each phrase in the table above.
4. Open **Shortcuts** → App Shortcuts → confirm all 8 Cronica shortcuts appear.
5. Run **Add from Link** with a TMDb / Letterboxd / IMDb URL.
6. Confirm **Settings → Siri & Shortcuts** opens the Shortcuts gallery.

See also `Docs/QA-SMOKE-TEST.md` (Siri section).

## Localization

Siri UI strings live in `Shared/Localization/Localizable.xcstrings`. After adding new intent copy:

```bash
python3 Scripts/apply_siri_localizations.py   # seed new keys
python3 Scripts/check_localization.py
```

Voice recognition uses the system language; phrase templates use your localized app name via `\(.applicationName)`.

## Info.plist

- `NSSiriUsageDescription` — permission string
- `INAlternativeAppNames` — “Chronica” pronunciation fallback

## Limits

- **10 app shortcuts max** per app (Cronica uses 8).
- Parameterized phrases require **AppEntity** parameters (not raw `String`).
- **Open Title** stores a pending `cronica://` URL in the App Group; the app consumes it on launch.

## Related

- In-app strings: `Docs/LOCALIZATION.md`
- App Store release notes (separate): `Docs/FASTLANE.md`
