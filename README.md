# HeartSync

HeartSync is a SwiftUI iOS app for daily relationship check-ins, with local storage and sample data for demos. Requires iOS 17 or later.

## Live status

**Not live yet — blocked by Xcode/device release validation and an App Store or TestFlight release.** No live distribution URL is recorded in this repository. Source code and demo materials are available; their presence does not establish a shipped app or verified UI.

## MVP definition (#6)

Core user story: as someone who wants a more intentional relationship, I can record today's energy, connection, reflection, and intention, then revisit recent entries and see a simple relationship pulse on the same device.

Must-have screens:

- **Home:** pulse, streak, recent reflections, and a route to the daily check-in.
- **Check-In:** energy and connection ratings, note, intention, and save confirmation.
- **Moments:** saved history, with an understandable empty state.
- **Profile:** local partner details and demo/reset controls.

Must-have behavior: save a check-in, reload it after relaunch, show it in Home/Moments, and recover from cleared history. Sample entries are fictional demo data; pulse and streak are local summaries, not clinical measures or measured product success.

### Demo-ready acceptance criteria

- On a clean simulator install, onboarding leads into the four-tab navigation shell.
- Save a check-in and confirm its values in Home and Moments; relaunch and confirm persistence.
- Clear history, inspect the empty state, and save a fresh entry or explicitly restore sample data.
- Complete the flow offline without accounts, credentials, or a backend.
- The iOS build and all XCTest cases pass in macOS CI; a person reviews layout, keyboard interaction, and VoiceOver in Xcode/on device before calling the demo verified.

These are pass/fail acceptance criteria, not claimed results or invented usage metrics.

### Non-goals for this week

Authentication, backend/cloud or partner sync, notifications, HealthKit, third-party integrations, production analytics, medical advice, and App Store launch are outside this MVP. Existing backup export/restore, sharing, prompt suggestions, and launch-review helpers are supporting code, not additions to the core scope. Day 1 adds no product features.

## Home and the primary flow (#5)

Home shows one next action based on today's saved state: start your reflection, invite your partner, open the shared check-in, or recover unreadable data in Profile. The daily progress list distinguishes your response, your partner's response and the shared conversation. When both people have checked in, Home offers the rule-based conversation prompt directly.

The seven-day strip uses calendar days ending today, including daylight-saving changes. Missing days are shown explicitly, old/future entries are excluded from the Home average, and an empty week has no assumed score. The average is labelled as **your** recorded connection; it is not a measured relationship-health score. Moments are one tap away.

Check-In keeps save/continue controls at the bottom of the screen and retains the saved draft, so tapping save again cannot silently erase your reflection. Home's edit action loads your saved values. Recovery blocks the save action. Both people still share the same device and local data.

Focused simulator UI tests exercise Home → reflection → explicit partner consent → shared summary → relaunch, and capture empty/sample Home screenshots at accessibility text size in CI's `ios-test-results` artifact. Test launch/reset controls exist only in DEBUG and use a separate UserDefaults suite. CI screenshots and automated reachability checks do not replace Amartya's visual/VoiceOver or physical-device review.

## State and recovery (#3)

A fresh install starts with an empty history and a neutral partner profile. Fictional samples are opt-in through Profile's reset-sample-data control and are labelled on Home; previews seed their isolated storage explicitly. Clearing samples persists an empty state.

Profile, both people's responses, the current draft, and the sample-data flag are encoded together in a versioned local UserDefaults value. Drafts persist from the store as you edit, without depending on a particular screen. Existing unversioned data migrates on launch. If data cannot be decoded or validated, Home/Profile show recovery options instead of silently substituting sample history. Restore a valid JSON backup, or explicitly start fresh; the unreadable versioned bytes are retained on-device and old migration keys are left intact.

Backup restore rejects unsupported schema versions, ratings outside 1–5, duplicate IDs/days, excessive text/history, and payloads over 5 MB before replacing any current data. Legacy unversioned backups remain supported. This is local storage, not encrypted multi-user storage or cloud backup; deleting the app can remove it. Export a JSON backup before uninstalling.

## Couples check-in flow (#5)

Home now leads with **Today, together**. Save your energy, connection, reflection and intention, then choose **Continue together** or Home's **Add partner’s check-in**. Pass the device to your partner: they choose their own ratings, optionally add a reflection/intention, and explicitly consent to sharing on this device before saving. A daily comparison offers a concrete conversation prompt; both responses persist and appear in Moments, including partner-note search. Editing your response preserves theirs. Legacy entries and backups remain readable.

This is a **same-device, local-only couples app**, with no remote accounts, pairing, cloud sync, or privacy boundary between the two people. JSON backups include both responses. Existing text/share exports contain the first person's response only; review any export before sharing. No API service or key is required. The summary is a rule-based reflection prompt, not AI or a clinical assessment.

## App structure (#4)

- `HeartSync/App`: app entry point, four-tab navigation shell, and tab identifiers.
- `HeartSync/Screens`: Home, Check-In, Moments, Profile, and onboarding/recovery views. The existing app screens replace the original starter placeholder.
- `HeartSync/Models`: Foundation-only check-in, profile, snapshot, and backup value types.
- `HeartSync/Supporting`: observable store/persistence and visual theme.
- `HeartSync/Components`: shared metric card.
- `HeartSync/SampleData`: explicitly fictional fixtures and a preview container. Each preview uses a fresh UserDefaults suite for both store data and onboarding flags, so editing previews does not change normal app storage. The root preview offers sample-history and empty-history states.

The existing navigation and demo behavior are retained. Xcode groups mirror the folders, and every Swift source is registered in the app target. Preview rendering still requires Xcode; portable checks validate source registration, not SwiftUI behavior.

## Current implementation and verification

The source contains the four screens, onboarding/recovery shell, local UserDefaults persistence, sample history, profile editing, JSON backup export/restore, and sharing helpers. Store regression tests cover persistence, consecutive-day streaks, backup freshness, restore success/failure, cleared history, preview storage isolation, legacy decoding, partner-response persistence/backup round trips, and shared-summary rules. Code presence alone does not verify simulator behavior.

Linux cannot build SwiftUI/UIKit or run the iOS XCTest target. Run portable repository checks with:

```sh
python3 -m unittest discover -s scripts -p 'test_*.py' -v
```

CI runs those checks and builds/tests the iOS app on a macOS simulator, without signing credentials. Before opening a PR, push its branch and wait for the branch CI tests to pass. For local Xcode verification:

```sh
xcodebuild test -project HeartSync.xcodeproj -scheme HeartSync \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath .deriveddata CODE_SIGNING_ALLOWED=NO
```

Use an installed simulator name from `xcrun simctl list devices available`. Visual layout, accessibility, clipboard/share sheets, and device behavior still require a human Xcode/device review.

## Demo and release materials

- [Demo script](DEMO_SCRIPT.md)
- [Presenter checklist](PRESENTER_CHECKLIST.md)
- [Final handoff](FINAL_HANDOFF.md)
- [Release checklist](RELEASE_CHECKLIST.md)
- [Production plan](PRODUCTION_NEXT_WEEK.md)
- [Production risks](PRODUCTION_RISKS.md)

These are planning and handoff documents, not evidence of a release. Daily program reports live in [issue #7](https://github.com/Amartya2001-droid/HeartSync/issues/7).
