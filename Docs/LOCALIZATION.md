# In-app localization

Cronica localizes **46 languages** in `Shared/Localization/Localizable.xcstrings`:

| Locale | Language |
|--------|----------|
| `en` | English (primary) |
| `de` | German |
| `fr` | French |
| `it` | Italian |
| `pt-BR` | Portuguese (Brazil) |
| `pt-PT` | Portuguese (Portugal) |
| `sk` | Slovak |
| `es-MX` | Spanish (Mexico) |
| `es` | Spanish (Spain) |
| `ar` | Arabic |
| `bn` | Bengali |
| `ca` | Catalan |
| `zh-Hans` | Chinese (Simplified) |
| `zh-Hant` | Chinese (Traditional) |
| `hr` | Croatian |
| `cs` | Czech |
| `da` | Danish |
| `nl` | Dutch |
| `fi` | Finnish |
| `el` | Greek |
| `gu` | Gujarati |
| `he` | Hebrew |
| `hi` | Hindi |
| `hu` | Hungarian |
| `id` | Indonesian |
| `ja` | Japanese |
| `kn` | Kannada |
| `ko` | Korean |
| `ms` | Malay |
| `ml` | Malayalam |
| `mr` | Marathi |
| `nb` | Norwegian Bokmål |
| `or` | Odia |
| `pa` | Punjabi |
| `pl` | Polish |
| `ro` | Romanian |
| `ru` | Russian |
| `sl` | Slovenian |
| `sv` | Swedish |
| `ta` | Tamil |
| `te` | Telugu |
| `th` | Thai |
| `tr` | Turkish |
| `uk` | Ukrainian |
| `ur` | Urdu |
| `vi` | Vietnamese |

## Catalogs

| File | Purpose |
|------|---------|
| `Shared/Localization/Localizable.xcstrings` | In-app UI, intent titles/descriptions, Settings |
| `Shared/Localization/AppShortcuts.xcstrings` | Spoken Siri / App Shortcut phrases |
| `Shared/Localization/InfoPlist.xcstrings` | Privacy usage descriptions (Siri, Reminders, Calendars, Photos, …). Brand / UTType / alternate Siri names are kept with `shouldTranslate: false` because Xcode re-extracts them from Info.plist on build. |

## Machine translation (Google Cloud)

Bulk locale fills use the **official Cloud Translation API** (not the free web scrape):

```bash
# 1. Enable Cloud Translation API + create an API key in Google Cloud Console
# 2. Store the key (gitignored):
cp Scripts/google_translate_api_key.example Scripts/google_translate_api_key
# edit Scripts/google_translate_api_key — one line, the raw key

# Or: export GOOGLE_TRANSLATE_API_KEY=YOUR_KEY

# 3. Fill missing in-app locale maps (batched, resumes from checkpoints):
python3 Scripts/gen_new_locale_maps.py

# 4. Merge into Localizable.xcstrings:
python3 Scripts/apply_new_catalog_locales.py

# 5. Platform surfaces (Siri / Info.plist gaps):
python3 Scripts/fill_platform_new_locales.py
python3 Scripts/localize_platform_surfaces.py

# 6. App Store descriptions:
python3 Scripts/translate_store_descriptions.py --force
```

Never commit `Scripts/google_translate_api_key` or `Scripts/google_translate_api_key.json`.

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

`Scripts/localize_platform_surfaces.py` (with `Scripts/siri_dialog_localizations.py`) is the source of truth for App Shortcut phrases, Info.plist usage strings, intent dialogs, and platform UI copy across all catalog locales.

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
