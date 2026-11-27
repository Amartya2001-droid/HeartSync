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

## Backup files

Profile can **Save backup file** through the native file exporter or **Open backup file for review** through the native importer. Files use the existing JSON backup format, including both perspectives. Imported files must be regular UTF-8 files no larger than 5 MB and pass the existing schema/rating/history checks before populating the preview. Nothing is restored until you choose **Restore reviewed backup** and confirm replacement.

File saving marks a backup current only after the exporter reports success and the exported snapshot still matches current data. A cancelled/failed save is not recorded as an export; edits made while the save panel is open keep the older snapshot from being labelled current. The clipboard flow remains available, but a clipboard copy is temporary. Backup files are readable JSON, not encrypted archives; review the destination before sharing.

Profile also offers **Verify backup file**: select a file to re-read it and compare its validated profile, both responses, draft and sample flag with local state. JSON formatting, export labels and history order do not affect comparison. Results distinguish a match, an earlier successful file export from this app session that is now stale, a mismatch of unknown age/origin, or an unverifiable file/state. Prior export evidence is held only in memory; after relaunch an older mismatching file has unknown age. Verification never restores data, changes the restore preview, or marks an export current. A result is invalidated when local state differs; later external file changes are not monitored, so select it again to re-check. Native picker/provider and physical-device/VoiceOver review remain pending.

Unit tests write/read real temporary files, restore both perspectives, reject oversized/empty/binary/folder inputs, and verify stale-export handling. Simulator UI tests check file actions are reachable; actual native picker/provider interactions, permissions and transfers on physical devices remain Amartya's manual review. No signing or new API service is required to build the feature.

## Branding and launch assets (#1)

The review candidate uses a paired-heart icon and **A small pause, together** lockup in welcome/About, with a native warm launch background and clearer shared-device/empty-state copy. The app icon is a full-square opaque 1024×1024 RGB PNG; iOS supplies the mask. The original AI-generated candidate and its asset exports are recorded in [the asset guide](release/ASSET_GUIDE.md).

[Candidate store copy](release/APP_STORE_COPY.json) describes the actual local couples flow. It has not been submitted. The existing bundle identity and configured version/build are retained; no signing, registration or release approval is implied. Support/privacy/distribution URLs remain unset rather than invented. Final branding, store screenshots/privacy answers, Xcode/device/VoiceOver review and signing/distribution await Amartya. Merges belong to Scipio; agent-created PRs stay open for review.

## QA and demo (#2)

Profile saves now validate and trim input, report persistence failure, and preserve the last saved profile instead of claiming success for unsaved edits. Backup copy refuses unreadable/invalid active state and does not mark it current. Weekly summary statistics use actual calendar days ending today, show unrecorded periods explicitly, and retain fractional averages in text exports. The unsupported ritual symbol `feather.fill` is replaced with `leaf.fill`.

The shared test scheme includes profile-validation/relaunch UI coverage, data-safety regressions and a check that every recommended ritual symbol exists in the simulator. Follow the [QA checklist](QA_CHECKLIST.md) and [current demo script](DEMO_SCRIPT.md). Focused CI layout tests and captures cover their stated cases; broader layouts, VoiceOver, physical devices and signing/distribution remain unverified here and are Amartya's calls.

The QA follow-up also keeps restore feedback at the restore action and disables unavailable sample/clear actions while saved data is unreadable. Store methods report blocked mutations without changing recovery data. Simulator tests cover cancelling clear-history, clearing/restoring a paired backup, relaunch, and an explicit fresh start from unreadable data. Fixture switches are DEBUG-only and confined to the UI-test storage suite.

## Home and the primary flow (#5)

First-launch onboarding leads directly to Check-In without an extra empty-history detour. Home shows one next action based on today's saved state: start your reflection, invite your partner, open the shared check-in, or recover unreadable data in Profile. The daily progress list distinguishes your response, your partner's response and the shared conversation. When both people have checked in, Home offers the rule-based conversation prompt directly.

The seven-day strip uses calendar days ending today, including daylight-saving changes. Missing days are shown explicitly, old/future entries are excluded from the Home average, and an empty week has no assumed score. The average is labelled as **your** recorded connection; it is not a measured relationship-health score. Moments are one tap away.

Check-In keeps save/continue controls at the bottom of the screen and retains the saved draft, so tapping save again cannot silently erase your reflection. Home's edit action loads your saved values. Recovery blocks the save action. Both people still share the same device and local data.

Focused simulator UI tests exercise first-launch routing and Home → reflection → explicit partner consent → shared summary → relaunch, and assert that the primary action stays within the screen width at accessibility text size; they also capture empty/sample Home screenshots in CI's `ios-test-results` artifact. Test launch/reset controls exist only in DEBUG and use a separate UserDefaults suite. CI screenshots and automated reachability checks do not replace Amartya's visual/VoiceOver or physical-device review.

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

CI runs those checks, selects the explicitly configured stable Xcode 26.3 toolchain, verifies an iPhoneOS 26+ SDK, builds unsigned Release for generic iOS devices, and runs Debug XCTest on an available iOS 26+ iPhone simulator. It fails rather than falling back to an older SDK/runtime. The unsigned Release build log and simulator results are retained as CI artifacts. This does not produce a signed archive or establish App Store upload, device/VoiceOver acceptance, or distribution. Before opening a PR, push its branch and wait for the branch CI tests to pass. For local Xcode verification:

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
