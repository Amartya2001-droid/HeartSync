# HeartSync

HeartSync is a lightweight SwiftUI MVP for daily relationship check-ins.

## This week's MVP

- A polished dashboard that shows relationship pulse, streak, weekly range, and recent reflections
- Connection trend storytelling and quick actions from Home
- A daily check-in flow for energy, connection, notes, and intention
- Quick prompt suggestions and coaching hints to make check-ins easier during demos and first use
- A searchable and sortable moments view for recent history, pattern scanning, and sharing individual entries
- Local persistence for demo-ready state without requiring a backend
- Basic profile customization, presets, readiness summary, backup-export status, presenter talk-track copy, and full history export
- Accessibility-focused semantics for key cards and status surfaces in Home, Check-In, Moments, and Profile
- A real `HeartSyncTests` XCTest target covering store persistence, streak logic, and backup-export freshness
- A dedicated cleared-history recovery sheet that guides users into a new first check-in or restores sample data

## Explicit non-goals

- Authentication
- Backend services or cloud sync
- Notifications
- HealthKit or other third-party integrations
- Production analytics and CI/CD

## Build note

In constrained environments, `xcodebuild` may need a custom `-derivedDataPath` inside the workspace. On machines where `xcode-select` points at Command Line Tools instead of full Xcode, switch the developer directory before running a full simulator build.

## Tests

- The repo now includes a `HeartSyncTests` target with focused `HeartSyncStore` coverage.
- Run the tests from Xcode, or from the terminal once `xcode-select` points to full Xcode.

## Demo materials

- See [DEMO_SCRIPT.md](/Users/amartyakarmakar/Documents/Codex1/HeartSync/DEMO_SCRIPT.md) for a short presenter flow.
- See [PRESENTER_CHECKLIST.md](/Users/amartyakarmakar/Documents/Codex1/HeartSync/PRESENTER_CHECKLIST.md) for a quick run-through before showing the app.
- See [FINAL_HANDOFF.md](/Users/amartyakarmakar/Documents/Codex1/HeartSync/FINAL_HANDOFF.md) for the close-out project summary.
- See [RELEASE_CHECKLIST.md](/Users/amartyakarmakar/Documents/Codex1/HeartSync/RELEASE_CHECKLIST.md) for the final validation pass in Xcode.
- See [PRODUCTION_NEXT_WEEK.md](/Users/amartyakarmakar/Documents/Codex1/HeartSync/PRODUCTION_NEXT_WEEK.md) for the launch-week production plan.
- See [PRODUCTION_RISKS.md](/Users/amartyakarmakar/Documents/Codex1/HeartSync/PRODUCTION_RISKS.md) for the main remaining risks.

## Demo flow

1. Let the onboarding sheet introduce the app on first launch, or replay it from Profile.
2. Open the Home tab and introduce the weekly pulse, streak, connection trend, and support focus.
3. Use the Home quick actions to move into Check-In.
4. Show how coaching hints and prompt suggestions help a couple log energy, connection, and one intention.
5. Save a new entry and point out the saved confirmation.
6. Move back to Home or Moments to show the update reflected in history.
7. Use Moments search, sort, empty-state actions, and individual sharing to explain retrieval and handoff.
8. Use Profile to confirm demo readiness, check backup-export status, switch presets, copy the presenter talk track, share the weekly summary, or export the full moments history.

## Best next improvements

- Replace placeholder app icon assets with final brand artwork
- Add screenshots for handoff
- Add import or restore-from-backup flow instead of export-only recovery
- Polish copy, spacing, and VoiceOver behavior after device-level review in Xcode
