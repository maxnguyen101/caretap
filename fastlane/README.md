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

### ios build_release

```sh
[bundle exec] fastlane ios build_release
```

Build a Release IPA for App Store Connect. Does not upload or submit.

### ios upload_metadata_only

```sh
[bundle exec] fastlane ios upload_metadata_only
```

Upload TapCare App Store metadata/screenshots only. Does not upload a binary or submit for review.

### ios upload_build_only

```sh
[bundle exec] fastlane ios upload_build_only
```

Upload an existing IPA only. Does not upload metadata/screenshots or submit for review.

### ios upload_everything_except_submit

```sh
[bundle exec] fastlane ios upload_everything_except_submit
```

Build and upload binary plus metadata/screenshots. Stops before App Review submission.

### ios preview_submission_package

```sh
[bundle exec] fastlane ios preview_submission_package
```

Print the local TapCare submission package paths and current safety settings.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
