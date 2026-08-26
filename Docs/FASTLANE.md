# Fastlane — App Store release notes

Cronica uses [Fastlane](https://fastlane.tools) to push localized **What’s New** text to App Store Connect in one command instead of editing each locale by hand.

## One-time setup

1. Use Ruby 3.2+ (see `.ruby-version`; `rbenv install` if needed) and install gems:

   ```bash
   bundle install
   ```

2. Create an **App Store Connect API key** (Users and Access → Integrations → App Store Connect API). Download the `.p8` file and store it **outside** the repo (e.g. `~/.appstoreconnect/`).

3. Export credentials in your shell (add to `~/.zshrc` if you like):

   ```bash
   export APP_STORE_CONNECT_KEY_ID="YOUR_KEY_ID"
   export APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_UUID"
   export APP_STORE_CONNECT_KEY_PATH="$HOME/.appstoreconnect/AuthKey_YOUR_KEY_ID.p8"
   ```

## Every release

Edit the single source file if the note changes:

```text
fastlane/release_notes/default.txt
```

Then upload to all store locales (en-US, de-DE, fr-FR, it, pt-BR, sk, es-MX):

```bash
bundle exec fastlane ios upload_release_notes
```

That lane copies `default.txt` into each `fastlane/metadata/<locale>/release_notes.txt` and runs `deliver` with **no binary upload**.

## Other lanes

| Lane | Purpose |
|------|---------|
| `bundle exec fastlane ios sync_release_notes` | Refresh locale files from `default.txt` only |
| `bundle exec fastlane ios upload_metadata` | Upload whatever is already in `fastlane/metadata/` |
| `bundle exec fastlane ios download_metadata` | Pull current ASC metadata into the repo (bootstrap) |

## Notes

- Apple has **no** native “paste once, fill all languages” for release notes; Fastlane `deliver` is the usual fix.
- Upload the build itself still happens via Xcode Organizer or Transporter; this tooling is for **metadata**.
- To use different text per locale, edit individual files under `fastlane/metadata/<locale>/release_notes.txt` instead of relying on `default.txt`.
