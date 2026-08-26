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

## Adding or updating strings

1. Add or edit the string in Xcode’s String Catalog (`Shared/Localization/Localizable.xcstrings`).
2. Fill in translations for each locale in the catalog (or use Xcode’s export/import workflow).
3. Verify:

```bash
python3 Scripts/check_localization.py
python3 Scripts/audit_localization.py
```

## Notes

- Preserve format specifiers (`%lld`, `%@`, positional `%1$@`, etc.).
- Brand names (TMDB, SIMKL, Cronica) and person names stay untranslated.
- App Store **release notes** are separate — see `Docs/FASTLANE.md`.

## Siri & Shortcuts

Cronica registers App Intents on **iOS, iPadOS, macOS, and visionOS** (not watchOS or tvOS).

| Voice command (examples) | Action |
|--------------------------|--------|
| “Add *Dune* to Cronica” | Search TMDb → add to watchlist |
| “Remove *Severance* from my watchlist” | Remove local watchlist item |
| “Mark *Oppenheimer* as watched” | Mark watched (auto-adds if needed) |
| “Mark my next episode as watched” | Marks current Up Next episode |
| “What’s up next on Cronica?” | Reads Up Next queue |
| “Open *The Bear* in Cronica” | Deep-links into the app |

Intents live in `Shared/Intents/`. After changing phrases or parameters, rebuild so Xcode exports App Intents metadata.
