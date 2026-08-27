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
| `Shared/Intents/CronicaAppShortcuts.swift` | App Shortcuts provider (10 shortcuts) |
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
python3 Scripts/localize_platform_surfaces.py
python3 Scripts/check_localization.py
```

Voice recognition uses the system language. Spoken phrase templates are localized in `Shared/Localization/AppShortcuts.xcstrings` for all 31 app locales (keep `${applicationName}` / `${title}` tokens). Regenerate with `python3 Scripts/localize_platform_surfaces.py`.

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

## Home Screen quick actions (iPhone / iPad)

Long-press the Cronica app icon on the Home Screen to jump into common flows:

| Action | Behavior |
|--------|----------|
| **Search** | Opens the Search tab with the keyboard |
| **Watchlist** | Opens the Watchlist tab |
| **Up Next** | Opens Home → full Up Next episode list |
| **Mark Next Episode Watched** *(dynamic)* | Marks the first Up Next episode watched; appears only when Up Next has content |

### Architecture

| File | Role |
|------|------|
| `Shared/QuickActions/QuickActionCoordinator.swift` | In-memory + persisted navigation queue for quick actions and Siri |
| `Shared/QuickActions/QuickActionDebug.swift` | DEBUG console logging for shortcut delivery |
| `Shared/QuickActions/QuickActionManager.swift` | Registers static + dynamic shortcuts, handles selection |
| `Shared/QuickActions/QuickActionAppDelegate.swift` | App + scene delegate for cold/warm shortcut delivery |
| `Shared/QuickActions/QuickActionRefreshBridge.swift` | Refreshes shortcuts when watchlist / Up Next changes |
| `Shared/QuickActions/HomeScreenQuickAction.swift` | Shortcut type identifiers |
| `Shared/Intents/SiriNavigationBridge.swift` | Shared pending navigation queue (also used by Siri) |
| `Shared/Enums/Navigation/AppNavigationRoute.swift` | Home → Up Next list navigation route |

Dynamic shortcut titles refresh on **launch** and whenever the watchlist or episode progress changes (same hooks as Siri shortcut parameter refresh).

Shortcut delivery uses **both** app-delegate and scene-delegate entry points (`configurationForConnecting`, `sceneWillConnect`, `windowScenePerformAction`) so cold and warm launches work on scene-based SwiftUI lifecycle. `TabBarView` observes `QuickActionCoordinator` and retries navigation briefly on launch.

Mark Next Episode Watched shows haptic + success feedback, or an alert when Up Next is empty.

### UI tests

`CronicaUITests/QuickActionNavigationUITests.swift` simulates navigation via launch arguments:

```bash
-ui-testing -ui-test-quick-action search
```

### DEBUG logging

In Debug builds, watch Xcode console for `[Cronica QuickAction]` lines when shortcuts fire.

### Testing (physical device)

1. Build & run on iPhone.
2. Long-press the Cronica icon → confirm **Search**, **Watchlist**, and **Up Next** appear.
3. With TV shows in Up Next, confirm **Mark Next Episode Watched** appears with the show name as subtitle.
4. Tap each action (cold launch and while app is in background).
5. Confirm **Mark Next Episode Watched** updates episode progress and removes/refreshes the dynamic shortcut when Up Next is empty.

See `Docs/QA-SMOKE-TEST.md` (Home Screen quick actions section).

### Harmless Simulator console noise

These are **not app bugs** and usually do not appear on physical devices:

| Message | Cause |
|---------|--------|
| `iCloud account unavailable` | Simulator not signed into iCloud |
| `nw_connection_*` / `quic_*` | Network stack retries (TMDb, etc.) |
| `Attempted to fetch Auto Shortcuts… AppShortcutsProvider` | `linkd` unavailable in Simulator |
| `CHHapticPattern` / `hapticpatternlibrary.plist` | Simulator has no haptic library (keyboard focus) |
| `Snapshotting a view (UIKeyboardImpl)` | Simulator keyboard snapshot |

Successful quick actions log `[Cronica QuickAction] handle → deliver → consume → apply` in Debug builds.

## Control Center (iOS 18+)

| Control | Action |
|---------|--------|
| **Up Next** | Opens Home → Up Next list |
| **Mark Watched** | Marks next Up Next episode (opens app from widget extension; in-app mark without opening when run from Shortcuts) |

Add from **Settings → Control Center → Cronica**.

## Interactive Up Next widget

Medium/large Up Next widgets include a **Mark Watched** button. Posters still open the title via deep link.

## Spotlight

Watchlist titles are indexed for system Spotlight search. Tapping a result opens the title in Cronica via `onContinueUserActivity`. Index rebuilds on launch (daily) and on watchlist add/remove/archive.

## Reminders

Per-title **Add to Reminders** on item detail creates one `EKReminder` for the next release/episode date. Bulk calendar sync remains under Settings → Notifications → Calendar Sync.
