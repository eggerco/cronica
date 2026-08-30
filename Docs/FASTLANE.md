# Fastlane — App Store release notes

Cronica uses [Fastlane](https://fastlane.tools) to push localized **What's New** text (and store URLs) to App Store Connect in one command.

Authentication is **App Store Connect API key only** — no Apple ID, password, or 2FA prompts.

## One-time setup

1. Use Ruby 3.2+ (see `.ruby-version`) and install gems:

   ```bash
   bundle install
   ```

2. Create an **App Store Connect API key**  
   App Store Connect → Users and Access → Integrations → App Store Connect API → Generate API Key  
   (Admin or App Manager). Download the `.p8` once and note the **Key ID** and **Issuer ID**.

3. Configure credentials (pick one):

   **Local JSON + `.p8` file (recommended)**

   ```bash
   cp fastlane/api_key.json.example fastlane/api_key.json
   ```

   Edit `fastlane/api_key.json`: set `key_id`, `issuer_id`, and `key_filepath` to your downloaded `AuthKey_*.p8`  
   (e.g. `~/.appstoreconnect/AuthKey_….p8`). `fastlane/api_key.json` is gitignored.

   **Environment variables**

   ```bash
   export APP_STORE_CONNECT_API_KEY_KEY_ID="YOUR_KEY_ID"
   export APP_STORE_CONNECT_API_KEY_ISSUER_ID="YOUR_ISSUER_UUID"
   export APP_STORE_CONNECT_API_KEY_KEY_FILEPATH="$HOME/.appstoreconnect/AuthKey_YOUR_KEY_ID.p8"
   ```

   Short aliases (`APP_STORE_CONNECT_KEY_ID` / `ISSUER_ID` / `KEY_PATH`) still work.

## Every release

Edit the translated source files under `fastlane/release_notes/` (one file per App Store locale), then upload:

```bash
bundle exec fastlane ios upload_release_notes
```

### Store locales

All **50** App Store Connect metadata languages (deliver codes):

| File | App Store Connect language |
|------|---------------------------|
| `en-US.txt` | English (U.S.) — primary |
| `ar-SA.txt` | Arabic |
| `bn-BD.txt` | Bangla |
| `ca.txt` | Catalan |
| `zh-Hans.txt` | Chinese (Simplified) |
| `zh-Hant.txt` | Chinese (Traditional) |
| `hr.txt` | Croatian |
| `cs.txt` | Czech |
| `da.txt` | Danish |
| `nl-NL.txt` | Dutch |
| `en-AU.txt` | English (Australia) |
| `en-CA.txt` | English (Canada) |
| `en-GB.txt` | English (U.K.) |
| `fi.txt` | Finnish |
| `fr-FR.txt` | French |
| `fr-CA.txt` | French (Canada) |
| `de-DE.txt` | German |
| `el.txt` | Greek |
| `gu-IN.txt` | Gujarati |
| `he.txt` | Hebrew |
| `hi.txt` | Hindi |
| `hu.txt` | Hungarian |
| `id.txt` | Indonesian |
| `it.txt` | Italian |
| `ja.txt` | Japanese |
| `kn-IN.txt` | Kannada |
| `ko.txt` | Korean |
| `ms.txt` | Malay |
| `ml-IN.txt` | Malayalam |
| `mr-IN.txt` | Marathi |
| `no.txt` | Norwegian |
| `or-IN.txt` | Odia |
| `pl.txt` | Polish |
| `pt-BR.txt` | Portuguese (Brazil) |
| `pt-PT.txt` | Portuguese (Portugal) |
| `pa-IN.txt` | Punjabi |
| `ro.txt` | Romanian |
| `ru.txt` | Russian |
| `sk.txt` | Slovak |
| `sl-SI.txt` | Slovenian |
| `es-MX.txt` | Spanish (Mexico) |
| `es-ES.txt` | Spanish (Spain) |
| `sv.txt` | Swedish |
| `ta-IN.txt` | Tamil |
| `te-IN.txt` | Telugu |
| `th.txt` | Thai |
| `tr.txt` | Turkish |
| `uk.txt` | Ukrainian |
| `ur-PK.txt` | Urdu |
| `vi.txt` | Vietnamese |

When the English copy changes, update `en-US.txt` first, then refresh the other locale files before uploading.

### App Store description

Source copy lives in `fastlane/description/` (one file per store locale). Regenerate translations from English with:

```bash
python3 Scripts/translate_store_descriptions.py --force
bundle exec fastlane ios upload_descriptions
```

`upload_descriptions` syncs `description.txt` (+ release notes / URLs) into `metadata/` and uploads the locales listed in `ACTIVE_STORE_LOCALES`.

**Activating new store languages:** App Store Connect only accepts metadata for languages enabled under **App Information → Localizations**. Enabling a language requires a unique localized app name; if “Cronica” is taken in that language, pick an available variant in ASC, then add that locale code to `ACTIVE_STORE_LOCALES` in `fastlane/Fastfile` and re-run upload. Translated files for all 50 languages already live in `fastlane/release_notes/` and `fastlane/description/`.

In-app UI localization (`Localizable.xcstrings`) is separate — see `Docs/LOCALIZATION.md`.

## Platforms

`upload_release_notes` / `upload_metadata` push the same localized metadata to every App Store platform for this app:

| Deliver `platform` | Store |
|--------------------|--------|
| `ios` | iPhone / iPad |
| `osx` | Mac |
| `appletvos` | Apple TV |
| `xros` | Apple Vision |

Watch App Store listing metadata ships with the iOS companion — there is no separate `watchos` deliver target.

If a platform has no editable version yet in App Store Connect (common before the first build for that OS is prepared), that platform fails the lane — fix ASC or upload a build, then re-run.

## Store URLs

Every locale gets the same App Store Connect URLs (written into `metadata/<locale>/`):

| File | URL |
|------|-----|
| `marketing_url.txt` | `https://www.cronica.watch` |
| `support_url.txt` | `https://www.cronica.watch/support` |

Change the constants in `fastlane/Fastfile`, then run `sync_store_urls` (or `sync_release_notes`, which also refreshes them).

## Other lanes

| Lane | Purpose |
|------|---------|
| `bundle exec fastlane ios sync_release_notes` | Copy `release_notes/*.txt` → `metadata/` and refresh store URLs |
| `bundle exec fastlane ios sync_descriptions` | Copy `description/*.txt` → `metadata/<locale>/description.txt` |
| `bundle exec fastlane ios sync_store_urls` | Write marketing / support URLs for all locales |
| `bundle exec fastlane ios upload_descriptions` | Sync descriptions + release notes, then upload metadata |
| `bundle exec fastlane ios upload_metadata` | Upload metadata to iOS, macOS, tvOS, and visionOS |
| `bundle exec fastlane ios download_metadata` | Pull current ASC metadata from iOS (bootstrap) |

## Notes

- Upload the IPA/build via Xcode Organizer or Transporter; this tooling is **metadata only**.
- `fastlane/metadata/` is generated by sync lanes — edit sources in `fastlane/release_notes/` and `fastlane/description/` instead.
- Never commit `.p8` keys or `fastlane/api_key.json`.
