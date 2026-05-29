# HeartSync Production Next Week

## Objective

Move HeartSync from polished demo MVP to a production-ready first release candidate.

## What is already in place

- Core Home, Check-In, Moments, and Profile flows
- Local persistence
- Export and handoff tools
- Demo and release checklists
- Safer destructive controls for sample data and history

## Highest-priority production tasks

### 1. Real Apple build validation

- Open the project in full Xcode
- Confirm `xcode-select` points to full Xcode, not Command Line Tools
- Build the app on Simulator
- Run the app on a physical device
- Validate all share and copy flows on device

### 2. Product hardening

- Add a real empty-state onboarding path when history is cleared
- Add automated tests for `HeartSyncStore`
- Validate all persistence paths after app relaunch
- Review accessibility labels, Dynamic Type, and contrast

### 3. Release setup

- Replace any remaining placeholder branding or metadata
- Confirm bundle identifier and signing configuration
- Set app version/build number
- Prepare screenshots and release notes

### 4. Decide production scope

HeartSync is still local-first today. Before calling it production-ready, decide whether v1 is:

- a local-only single-user app
- or a cloud-backed multi-user app

If cloud-backed is required, that is a separate implementation track and not a one-week polish task.

## Suggested order for next week

1. Full Xcode + device validation
2. Automated tests for store logic
3. Accessibility/content polish
4. Signing, metadata, screenshots, and release packaging

## Go / no-go

### Go if

- The app builds in Xcode
- Core flows work on device
- Share/copy flows behave correctly
- Release metadata is complete

### No-go if

- Build/signing is still unstable
- History persistence is unreliable
- Accessibility or layout breaks on target devices
