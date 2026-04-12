# HeartSync

HeartSync is a lightweight SwiftUI MVP for daily relationship check-ins.

## This week's MVP

- A polished dashboard that shows relationship pulse, streak, and recent reflections
- Connection trend storytelling and quick actions from Home
- A daily check-in flow for energy, connection, notes, and intention
- Quick prompt suggestions and coaching hints to make check-ins easier during demos and first use
- A searchable moments view for recent history and pattern scanning
- Local persistence for demo-ready state without requiring a backend
- Basic profile customization, presets, and demo readiness checks

## Explicit non-goals

- Authentication
- Backend services or cloud sync
- Notifications
- HealthKit or other third-party integrations
- Production analytics and CI/CD

## Build note

In constrained environments, `xcodebuild` may need a custom `-derivedDataPath` inside the workspace. On machines where `xcode-select` points at Command Line Tools instead of full Xcode, switch the developer directory before running a full simulator build.

## Demo materials

- See [DEMO_SCRIPT.md](/Users/amartyakarmakar/Documents/Codex1/HeartSync/DEMO_SCRIPT.md) for a short presenter flow.
- See [PRESENTER_CHECKLIST.md](/Users/amartyakarmakar/Documents/Codex1/HeartSync/PRESENTER_CHECKLIST.md) for a quick run-through before showing the app.

## Demo flow

1. Let the onboarding sheet introduce the app on first launch, or replay it from Profile.
2. Open the Home tab and introduce the weekly pulse, streak, connection trend, and support focus.
3. Use the Home quick actions to move into Check-In.
4. Show how coaching hints and prompt suggestions help a couple log energy, connection, and one intention.
5. Save a new entry, then move back to Home or Moments to show the update reflected in history.
6. Use Moments search to find a note, intention, or date label.
7. Use Profile to confirm demo readiness, switch presets, or share the weekly summary.

## Best next improvements

- Replace placeholder app icon assets with final brand artwork
- Add screenshots for handoff
- Add tests around store persistence and streak calculation
- Polish copy and spacing after device-level review in Xcode
