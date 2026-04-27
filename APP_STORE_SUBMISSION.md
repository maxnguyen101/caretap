# TapCare App Store Submission Runbook

Last updated: April 25, 2026.

This runbook is for submitting the current iOS app to App Store Connect under the public App Store brand **TapCare**. The Xcode project, scheme, bundle identifiers, and some internal source names still use `CareTap`; those are internal technical names and were not changed.

## Submission Status

Prepared locally:

- App Store metadata in `fastlane/metadata/en-US`
- App Review notes in `fastlane/metadata/review_information`
- Fastlane lanes in `fastlane/Fastfile`
- Signed App Store IPA at `build/app-store/TapCare.ipa`
- dSYM archive at `build/app-store/TapCare.app.dSYM.zip`
- Five 6.9-inch iPhone screenshots in `fastlane/screenshots/en-US`
- No TapCare Premium or in-app purchase metadata
- `submit_for_review` is explicitly false in every upload lane

Not done automatically:

- Final click on "Submit for Review"
- App Review contact phone number, because it must be a real reachable number supplied by you
- App Store Connect upload, because both local `.p8` keys failed API authentication
- Any App Store Connect login challenge or account permission issue after valid credentials are provided

Upload blocker found April 25, 2026:

```text
Authentication credentials are missing or invalid. Provide a properly configured and signed bearer token.
```

To clear it, provide a valid App Store Connect API key plus issuer ID, or sign in/upload through Xcode Organizer with an Apple account that can manage `com.maxnguyen.caretap`.

## Current Project Facts

| Field | Value |
|---|---|
| Public App Store name | `TapCare` |
| Local Xcode project | `CareTap.xcodeproj` |
| Local scheme | `CareTap` |
| Main bundle ID | `com.maxnguyen.caretap` |
| Widget bundle ID | `com.maxnguyen.caretap.widget` |
| App group | `group.com.maxnguyen.caretap.shared` |
| Associated domain | `applinks:vercel-links-mu.vercel.app` |
| URL scheme | `caretap` |
| Apple Developer Team | `R662BH835Y` |
| Deployment target | iOS 18.0 |
| App Store version | `1.0` |
| Build number | `1` |
| Export encryption flag | `ITSAppUsesNonExemptEncryption = false` |

Local verification already performed:

```sh
xcodegen generate
xcodebuild -project CareTap.xcodeproj -scheme CareTap -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.4' build
```

Result: `BUILD SUCCEEDED`.

## App Store Connect App Record

Create or confirm the App Store Connect app:

| Field | Fill in |
|---|---|
| Platform | iOS |
| Name | `TapCare` |
| Primary Language | English (U.S.) |
| Bundle ID | `com.maxnguyen.caretap` |
| SKU | `com.maxnguyen.caretap.ios` |
| User Access | Full Access |

## App Information

| Field | Fill in |
|---|---|
| Name | `TapCare` |
| Subtitle | `Routine Check-Ins for Families` |
| Primary Category | Health & Fitness |
| Secondary Category | Medical |
| Content Rights | The app does not contain, show, or access third-party content. |
| License Agreement | Apple's Standard License Agreement |

## Pricing And Availability

| Field | Fill in |
|---|---|
| Price | Free |
| Availability | United States for first release |
| iPhone/iPad apps on Apple silicon Macs | Not available for first release |
| Apple Vision Pro compatibility | Not available for first release |
| Release option | Manually release this version after App Review approval |

## In-App Purchases

Do not create or attach any in-app purchases for this release. TapCare Premium is not part of this submission.

If App Store Connect shows old or draft subscription products, do not add them to the iOS 1.0 version and do not submit them for review.

## App Privacy

Answer "Yes, we collect data from this app." Then disclose:

| Data type | Used for | Linked to user? | Tracking? |
|---|---|---:|---:|
| Contact Info - Name | App Functionality | Yes | No |
| Contact Info - Email Address | App Functionality | Yes | No |
| Identifiers - User ID | App Functionality | Yes | No |
| Health & Fitness - Health | App Functionality | Yes | No |
| Other Data - Other Data Types | App Functionality | Yes | No |

Do not select advertising, marketing, analytics, product personalization, or tracking for any data type.

Use this interpretation:

- Health: medication names, schedules, dose occurrences, dose logs, reminder preferences, refill estimates, and notes.
- Other Data Types: app role, caregiver relationship or invitation state, time zone and locale for schedules, and NFC tag association identifiers.
- Purchases: do not select, because this release does not include TapCare Premium or in-app purchases.

Privacy URLs:

| Field | Fill in |
|---|---|
| Privacy Policy URL | `https://tapcare.app/legal/privacy` |
| User Privacy Choices URL | Leave blank |

Publish the privacy answers after saving.

## Age Rating

Use these answers for the current build:

| Section | Answer |
|---|---|
| Parental Controls | No |
| Age Assurance | No |
| Unrestricted Web Access | No |
| User-Generated Content | No |
| Messaging and Chat | No |
| Advertising | No |
| Profanity or Crude Humor | None |
| Horror/Fear Themes | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Medical or Treatment Information | Infrequent |
| Health or Wellness Topics | None |
| Mature or Suggestive Themes | None |
| Sexual Content or Nudity | None |
| Violence categories | None |
| Contests | None |
| Simulated Gambling | None |
| Gambling | No |
| Loot Boxes | No |
| Made for Kids | Not Applicable |
| Override to Higher Age Rating | Not Applicable |
| Age Suitability URL | Leave blank |

If App Store Connect asks whether TapCare is regulated health hardware/software, answer No. TapCare is a personal organization and routine-support tool; it does not provide medical advice, diagnosis, or treatment.

## Version Metadata

The exact text is already stored in `fastlane/metadata/en-US`.

| Field | Value |
|---|---|
| Name | `TapCare` |
| Subtitle | `Routine Check-Ins for Families` |
| Promotional Text | `Support medication, vitamin, and supplement routines with simple check-ins, reminders, refill estimates, and optional family visibility.` |
| Keywords | `routine,medication,vitamin,supplement,caregiver,family,reminder,NFC,pill,check-in` |
| Support URL | `https://tapcare.app/legal/support` |
| Marketing URL | `https://tapcare.app` |
| Privacy URL | `https://tapcare.app/legal/privacy` |
| Copyright | `2026 Maxwell Nguyen` |

## App Review Information

Use a real App Review contact phone number. Fastlane reads it from:

```sh
export TAPCARE_REVIEW_PHONE="+1XXXXXXXXXX"
```

Then use:

| Field | Fill in |
|---|---|
| First name | `Maxwell` |
| Last name | `Nguyen` |
| Phone | Your real reachable review phone number |
| Email | `support@tapcare.app` |
| Sign-in required | No |
| Demo username | Leave blank |
| Demo password | Leave blank |

Review notes are stored in `fastlane/metadata/review_information/notes.txt`. The important review path is:

1. Choose "For me".
2. Continue locally on this iPhone.
3. Add a medication and schedule.
4. Skip NFC pairing if no NFC tag is available.
5. Manually log a dose.
6. Review settings, legal pages, export, and account deletion paths.

## Screenshots

Upload 6.9-inch iPhone portrait screenshots. App Store Connect accepts one to ten screenshots per display size; highest-resolution iPhone screenshots can scale down to smaller iPhone sizes.

Use 5 or 6 screenshots:

1. Today/home dashboard with a due or upcoming dose.
2. Add medication or schedule setup.
3. NFC pairing screen with manual fallback visible.
4. Dose history or medication detail.
5. Caregiver/shared access screen.
6. Settings page showing privacy, legal, export, and deletion access.

Store files here before running Fastlane screenshot upload:

```text
fastlane/screenshots/en-US/
```

Current upload-ready screenshot files:

```text
01_onboarding.png
02_add_medication.png
03_routine_details.png
04_home_dashboard.png
05_workspace.png
```

Do not upload an app preview video for the first release unless you already have a polished video. Screenshots are enough.

## Fastlane Commands

Show available lanes:

```sh
fastlane lanes
```

Build an App Store IPA locally:

```sh
fastlane ios build_release
```

Upload metadata and screenshots only, without a binary and without submitting:

```sh
export TAPCARE_REVIEW_PHONE="+1XXXXXXXXXX"
fastlane ios upload_metadata_only
```

Upload an existing IPA only, without metadata, screenshots, or review submission:

```sh
export TAPCARE_REVIEW_PHONE="+1XXXXXXXXXX"
IPA_PATH="build/app-store/TapCare.ipa" fastlane ios upload_build_only
```

Build and upload binary plus metadata/screenshots, still without submitting:

```sh
export TAPCARE_REVIEW_PHONE="+1XXXXXXXXXX"
fastlane ios upload_everything_except_submit
```

Authentication defaults to the local App Store Connect API key:

```text
~/.appstoreconnect/private_keys/AuthKey_H53X5AB675.p8
```

If App Store Connect requires a different key, set:

```sh
export APP_STORE_CONNECT_API_KEY_KEY_ID="YOUR_KEY_ID"
export APP_STORE_CONNECT_API_KEY_ISSUER_ID="YOUR_ISSUER_ID_OR_LEAVE_EMPTY_FOR_INDIVIDUAL_KEY"
export APP_STORE_CONNECT_API_KEY_KEY_FILEPATH="/absolute/path/to/AuthKey.p8"
```

Every lane sets `submit_for_review: false`. You still need to manually click "Add for Review" and then "Submit for Review" in App Store Connect when you are ready.

## Xcode Upload Path

If you prefer Xcode Organizer:

1. Open `CareTap.xcodeproj`.
2. Select scheme `CareTap`.
3. Select destination `Any iOS Device (arm64)`.
4. Confirm signing team is `R662BH835Y`.
5. Product > Clean Build Folder.
6. Product > Archive.
7. Organizer opens after archive.
8. Select the archive.
9. Click Distribute App.
10. Choose App Store Connect.
11. Choose Upload.
12. Keep "Upload your app's symbols" enabled.
13. Use automatic signing.
14. Upload.
15. Wait for processing in App Store Connect.

## Final App Store Connect Checklist

Before the final submit click:

- App name is `TapCare`, not `CareTap`.
- No TapCare Premium subscriptions or in-app purchases are attached.
- Build `1.0 (1)` is selected.
- Screenshots are uploaded.
- App Privacy answers match the privacy manifest.
- Age rating is complete.
- Review contact phone number is real.
- Review notes say local use is available and NFC is optional.
- Export compliance says no non-exempt encryption.
- Release option is manual release.

Only after those are green:

1. App Store Connect > My Apps > TapCare > App Store tab > iOS version `1.0`.
2. Add the processed build.
3. Click Add for Review.
4. Go to Draft Submissions.
5. Click Submit for Review.

## What Gets Uploaded

You upload:

- The archived app build / IPA, which includes the app binary, widget extension, app icon, privacy manifest, entitlements, launch screen, and Info.plist values.
- App Store metadata from `fastlane/metadata/en-US`.
- 6.9-inch iPhone screenshots from `fastlane/screenshots/en-US`.

You do not upload source code, legal text files, certificates, provisioning profiles, or privacy manifests manually.
