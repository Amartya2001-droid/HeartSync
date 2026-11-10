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

## Current implementation and verification

The source contains the four screens, onboarding/recovery shell, local UserDefaults persistence, sample history, profile editing, JSON backup export/restore, and sharing helpers. Six `HeartSyncStoreTests` cover persistence, consecutive-day streaks, backup freshness, restore success/failure, and cleared history. Code presence alone does not verify simulator behavior.

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
