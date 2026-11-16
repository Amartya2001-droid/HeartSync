# HeartSync branding and launch assets

Status: **review candidates; not submitted or released**. Scipio reviews/merges this PR. Xcode/device/VoiceOver review and signing/distribution remain Amartya's calls.

## Identity

- Name: **HeartSync**. Tagline: **A small pause, together.**
- Motif: two interlocking heart outlines, representing two perspectives. No ECG/medical symbolism or clinical outcome claims.
- Palette: warm peach, muted coral and dark burgundy/ink. The mark is decorative; text supplies the accessible app name.
- Positioning: shared-device daily reflection, explicit partner consent, local history and JSON backup. No remote pairing, account system or partner sync is implied.

## Assets in this repository

| Asset | Location | State |
| --- | --- | --- |
| App icon | `HeartSync/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` | 1024×1024, full-square opaque RGB PNG; iOS applies the mask |
| In-app mark | `HeartSync/Assets.xcassets/HeartSyncBrandMark.imageset` | 256×256 export; onboarding/About render a rounded mask |
| Original candidate | `release/source/HeartSync-icon-candidate-original.png` | AI-generated during Day 7 with image_gen; retained as the source before size/format export |
| Launch background | `HeartSyncLaunchBackground.colorset` + `Supporting/Info.plist` | Named native launch-screen background; no simulated loading or fake interactive launch screen |
| Reusable lockup | `HeartSync/Components/HeartSyncBrand.swift` | App name, mark, tagline and shared-device disclosure |
| Store copy | `release/APP_STORE_COPY.json` | Candidate text with local length checks; not an App Store listing |

Branding approval remains pending review.

## Metadata decisions

The existing configured bundle identifier `com.amartyakarmakar.heartsync`, version `1.0`, build `1` and development team are retained. They are existing project configuration, not proof of registration, entitlement, signing access, an approved release number or a live app. Amartya must confirm the final App Store Connect identity, version/build and provisioning.

Support, privacy-policy and distribution URLs are deliberately null in the candidate copy: none has been supplied or published. Do not replace them with invented destinations. Before submission, Amartya must approve real support/privacy destinations and review the app's local-storage/backup behavior, required-reason API/privacy-manifest requirements and App Store privacy answers. No compliance approval is claimed here.

## Screenshot/content plan

Use only real simulator/device captures with explicitly fictional data. No generated device mockup should be presented as an app screenshot.

1. Welcome: brand and shared-device disclosure. The onboarding UI test exports a review capture.
2. Home: the next action and recorded seven-day view, at normal and accessibility text sizes.
3. Check-In: ratings and reflection; keep real personal notes out of captures.
4. Together: both fictional perspectives and the rule-based prompt.
5. Moments: saved history/search and the empty state.
6. Profile: clear local-backup controls and version/About information.

CI exports review PNGs and an attachment manifest with the simulator identity. The current automated iPhone capture is not claimed to satisfy all App Store Connect screenshot sizes. Capture the accepted submission device classes in Xcode after Amartya's layout review; do not upscale a review image and label it a verified device capture. Final store screenshots, previews, app privacy answers and submission remain pending.
