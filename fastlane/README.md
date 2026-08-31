fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios sync_store_urls

```sh
[bundle exec] fastlane ios sync_store_urls
```

Write marketing_url / support_url for every store locale

### ios sync_release_notes

```sh
[bundle exec] fastlane ios sync_release_notes
```

Copy fastlane/release_notes/<locale>.txt into fastlane/metadata/

### ios sync_descriptions

```sh
[bundle exec] fastlane ios sync_descriptions
```

Copy fastlane/description/<locale>.txt into fastlane/metadata/<locale>/description.txt

### ios sync_keywords

```sh
[bundle exec] fastlane ios sync_keywords
```

Copy fastlane/keywords/<locale>.txt into fastlane/metadata/<locale>/keywords.txt

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Upload metadata to iOS, macOS, tvOS, and visionOS (no binary, no screenshots)

### ios upload_release_notes

```sh
[bundle exec] fastlane ios upload_release_notes
```

Sync localized release notes and upload to all App Store platforms

### ios upload_descriptions

```sh
[bundle exec] fastlane ios upload_descriptions
```

Sync localized descriptions (+ keywords / release notes / URLs) and upload to all App Store platforms

### ios upload_keywords

```sh
[bundle exec] fastlane ios upload_keywords
```

Sync localized keywords and upload to all App Store platforms

### ios download_metadata

```sh
[bundle exec] fastlane ios download_metadata
```

Download current App Store Connect metadata (iOS) into fastlane/metadata/

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
