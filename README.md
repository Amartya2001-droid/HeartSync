# HeartSync

HeartSync is a lightweight SwiftUI MVP for daily relationship check-ins.

## This week's MVP

- A polished dashboard that shows relationship pulse, streak, and recent reflections
- A daily check-in flow for energy, connection, notes, and intention
- Quick prompt suggestions to make check-ins easier during demos and first use
- A moments view for recent history
- Local persistence for demo-ready state without requiring a backend
- Basic profile customization for presenting the app with different names and milestones

## Explicit non-goals

- Authentication
- Backend services or cloud sync
- Notifications
- HealthKit or other third-party integrations
- Production analytics and CI/CD

## Build note

In constrained environments, `xcodebuild` may need a custom `-derivedDataPath` inside the workspace.

## Demo materials

- See [DEMO_SCRIPT.md](/Users/amartyakarmakar/Documents/Codex1/HeartSync/DEMO_SCRIPT.md) for a short presenter flow.
- See [PRESENTER_CHECKLIST.md](/Users/amartyakarmakar/Documents/Codex1/HeartSync/PRESENTER_CHECKLIST.md) for a quick run-through before showing the app.

## Demo flow

1. Let the onboarding sheet introduce the app on first launch, or replay it from Profile.
2. Open the Home tab and introduce the weekly pulse, streak, and support focus.
3. Open Check-In and show how quickly a couple can log energy, connection, and one intention.
4. Save a new entry, then move back to Home or Moments to show the update reflected in history.
5. Use the Profile tab to switch presets if you want a different presentation scenario.
6. Share the weekly summary from Profile to export a concise relationship snapshot.

## Best next improvements

- Replace placeholder app icon assets with final brand artwork
- Add screenshots and a short demo script for handoff
- Add tests around store persistence and streak calculation
- Polish copy and spacing after device-level review in Xcode
