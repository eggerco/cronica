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

### ios sync_release_notes

```sh
[bundle exec] fastlane ios sync_release_notes
```

Copy fastlane/release_notes/default.txt into every store locale

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Upload metadata only (no binary, no screenshots)

### ios upload_release_notes

```sh
[bundle exec] fastlane ios upload_release_notes
```

Sync default release notes and upload to App Store Connect

### ios download_metadata

```sh
[bundle exec] fastlane ios download_metadata
```

Download current App Store Connect metadata into fastlane/metadata/

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
