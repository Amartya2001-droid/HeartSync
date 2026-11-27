# Privacy API inventory — November 27, 2026

Technical source inventory, not App Store Connect approval, a published privacy policy, or legal certification. Re-audit when behavior/dependencies change. Amartya approves the final privacy answers and actual support/privacy URLs.

## Required-reason use

`HeartSync/Supporting/PrivacyInfo.xcprivacy` declares `NSPrivacyAccessedAPICategoryUserDefaults` with Apple's published `CA92.1` reason: access to this app's own defaults. The store reads/writes the local profile, both responses, draft, migration/recovery keys and export timestamps. `@AppStorage` stores this app's onboarding flags. Preview and DEBUG UI-test suites are isolated app-owned suites; there is no App Group or managed-device configuration access.

Source: `Supporting/HeartSyncStore.swift`, `App/ContentView.swift`, `App/HeartSyncApp.swift`, `Screens/SettingsView.swift`, `SampleData/HeartSyncPreview.swift`.

The backup reader requests regular-file and file-size metadata for a user-selected file and bounded content reading; it does not request creation/modification timestamps or available disk capacity. No system boot-time or active-keyboard enumeration was found. No third-party SDKs or application network/analytics/tracking code were found in the current project. Do not add speculative API reasons.

The manifest declares no tracking, tracking domains or developer data collection for this implementation. This does not mean user data cannot leave the device: the user can explicitly export readable JSON containing both responses, copy text or use the system share sheet/Files providers. These destination choices are not developer-operated account or cloud-sync services. Final App Store privacy answers must be checked against the release archive and any future dependencies.

## Packaging verification

The file is registered in the app target's Copy Bundle Resources phase. Portable checks parse the source and exercise missing/changed product failures; CI checks the actual unsigned Release app's copied manifest against source. Native XCTest reads it from the hosted simulator app bundle. These checks do not submit the app or replace Apple's signed-archive privacy report/upload validation.

## Apple references

- [Required reason categories and reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)
- [Adding required reason entries (TN3183)](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest)
- [Describing required reason API use](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)

Still pending: Amartya's final declarations, published policy/support destinations and in-app policy link, device/VoiceOver review, signed archive/report, signing and distribution. No live URL or approval is invented.
