# HeartSync

HeartSync is a lightweight SwiftUI MVP for daily relationship check-ins.

## This week's MVP

- A polished dashboard that shows relationship pulse, streak, and recent reflections
- A daily check-in flow for energy, connection, notes, and intention
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

## Demo flow

1. Open the Home tab and introduce the weekly pulse, streak, and support focus.
2. Open Check-In and show how quickly a couple can log energy, connection, and one intention.
3. Save a new entry, then move back to Home or Moments to show the update reflected in history.
4. Use the Profile tab to switch presets if you want a different presentation scenario.

## Best next improvements

- Replace placeholder app icon assets with final brand artwork
- Add a lightweight onboarding screen for first launch
- Add tests around store persistence and streak calculation
- Polish copy and spacing after device-level review in Xcode
