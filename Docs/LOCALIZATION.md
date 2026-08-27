# In-app localization

Cronica localizes **31 languages** in `Shared/Localization/Localizable.xcstrings`:

| Locale | Language |
|--------|----------|
| `en` | English (primary) |
| `de` | German |
| `fr` | French |
| `it` | Italian |
| `pt-BR` | Portuguese (Brazil) |
| `sk` | Slovak |
| `es-MX` | Spanish (Mexico) |
| `es` | Spanish (Spain) |
| `ar` | Arabic |
| `zh-Hans` | Chinese (Simplified) |
| `zh-Hant` | Chinese (Traditional) |
| `hr` | Croatian |
| `cs` | Czech |
| `da` | Danish |
| `nl` | Dutch |
| `fi` | Finnish |
| `el` | Greek |
| `he` | Hebrew |
| `hi` | Hindi |
| `hu` | Hungarian |
| `id` | Indonesian |
| `ja` | Japanese |
| `ko` | Korean |
| `ms` | Malay |
| `nb` | Norwegian Bokmål |
| `pl` | Polish |
| `ro` | Romanian |
| `ru` | Russian |
| `sv` | Swedish |
| `tr` | Turkish |
| `uk` | Ukrainian |

## Catalogs

| File | Purpose |
|------|---------|
| `Shared/Localization/Localizable.xcstrings` | In-app UI, intent titles/descriptions, Settings |
| `Shared/Localization/AppShortcuts.xcstrings` | Spoken Siri / App Shortcut phrases |
| `Shared/Localization/InfoPlist.xcstrings` | Privacy usage descriptions (Siri, Reminders, Calendars, Photos, …). Brand / UTType / alternate Siri names are kept with `shouldTranslate: false` because Xcode re-extracts them from Info.plist on build. |

## Adding or updating strings

1. Add or edit the string in the appropriate catalog (or in Swift with `String(localized:)` / `LocalizedStringResource`).
2. Provide a **real translation for every locale** — do not leave English copies marked as `translated`.
3. For **Siri spoken phrases**, update `AppShortcuts.xcstrings` (or regenerate via the script). Keep `${applicationName}` / `${title}` tokens intact.
4. Verify:

```bash
python3 Scripts/localize_platform_surfaces.py
python3 Scripts/check_localization.py
python3 Scripts/audit_localization.py
```

### Platform surfaces (Siri, Controls, Reminders)

`Scripts/localize_platform_surfaces.py` (with `Scripts/siri_dialog_localizations.py`) is the source of truth for App Shortcut phrases, Info.plist usage strings, intent dialogs, and platform UI copy across all 31 locales.

When adding a **new** Siri phrase or platform UI string:

1. Add the English phrase/title in Swift.
2. Add translations for all `LOCALES` in `Scripts/localize_platform_surfaces.py` / `Scripts/siri_dialog_localizations.py`.
3. Re-run the script and commit the catalogs.

## Notes

- Preserve format specifiers (`%lld`, `%@`, positional `%1$@`, etc.).
- Brand names (TMDB, SIMKL, Cronica) and person names stay untranslated.
- App Store **release notes** are separate — see `Docs/FASTLANE.md`.

## Siri & Shortcuts

Cronica registers App Intents on **iOS, iPadOS, macOS, and visionOS** (not watchOS or tvOS). See **`Docs/SIRI.md`** for architecture, testing, and maintenance.

Spoken phrases are localized in **`AppShortcuts.xcstrings`** so German (and other) Siri locales match natural speech (e.g. *„Füge Dune zu meiner Watchlist in Cronica hinzu“*).

| Voice command (examples, English) | Action |
|-----------------------------------|--------|
| “Add *Dune* to Cronica” | Search TMDb → add to watchlist |
| “Remove *Severance* from my watchlist” | Remove local watchlist item |
| “Mark *Oppenheimer* as watched” | Mark watched (auto-adds if needed) |
| “Mark my next episode as watched” | Marks current Up Next episode |
| “What’s up next on Cronica?” | Reads Up Next queue |
| “Open search in Cronica” | Opens Search tab |
| “Add this link to Cronica” | Add from shared URL |
| “Open *The Bear* in Cronica” | Deep-links into the app |
| “Open my watchlist in Cronica” | Opens Watchlist tab |
| “Open up next in Cronica” | Opens Up Next list |

After changing intents or phrases, rebuild and run `python3 Scripts/check_localization.py`.
