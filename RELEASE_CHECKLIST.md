# HeartSync Release Checklist

## In Xcode

- Confirm the active developer directory points to full Xcode
- Build the `HeartSync` scheme
- Run the `HeartSyncTests` target
- Run on at least one Simulator
- Run on one physical device if available
- Check the onboarding sheet presentation
- Check tab navigation and safe-area spacing

## Functional verification

- Save a new daily check-in
- Update an existing same-day check-in
- Search Moments
- Sort Moments newest-first and oldest-first
- Share one individual moment
- Copy weekly summary
- Copy presenter talk track
- Copy latest moment
- Copy full moments history
- Copy backup export and confirm `Data safety` updates
- Paste a copied backup and confirm restore replaces profile, moments, and draft state
- Reset sample data and confirm the app returns to the default scenario
- Clear all moments history and confirm the recovery sheet offers a new first check-in or sample-data restore

## Content verification

- Confirm the selected preset matches the intended demo story
- Confirm `Demo readiness` shows the expected state
- Confirm `Backup export is current` flips back to pending after a later edit
- Confirm the weekly range label looks correct
- Confirm exported text includes timestamp context

## Delivery

- Capture screenshots if needed
- Share `DEMO_SCRIPT.md`
- Share `PRESENTER_CHECKLIST.md`
- Share `FINAL_HANDOFF.md`
