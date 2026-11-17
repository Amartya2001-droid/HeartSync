# HeartSync release checklist

The app is **not live**. This checklist separates a tested source build from release approval.

## Source/CI review

- Review the feature PR and exact-head CI. Scipio owns merges; the agent must not self-merge.
- Run the shared `HeartSync` scheme, including unit and UI test targets.
- Inspect exported simulator captures and follow [QA_CHECKLIST.md](QA_CHECKLIST.md).
- Review the candidate icon, metadata and copy in [release/ASSET_GUIDE.md](release/ASSET_GUIDE.md).
- Confirm fresh install, paired check-in/relaunch, profile validation, backup restore/cancel and unreadable-state recovery.

## Amartya's Xcode/device/VoiceOver review — pending

- Inspect the icon on a real Home Screen and the native launch background.
- Review onboarding, all four tabs, empty/recovery states, keyboard and share/clipboard flows.
- Check VoiceOver reading order and consent, Dynamic Type, small-phone/iPad and landscape layouts beyond the focused CI assertions.
- Review local persistence and both-response JSON backups on device; store a backup safely before destructive tests.

## Distribution decisions — pending Amartya

- Confirm bundle registration, developer team, provisioning and final version/build numbers.
- Approve branding and real App Store screenshot/device classes and copy.
- Supply/approve real support and privacy-policy destinations and complete privacy/required-reason API review.
- Configure signing and choose TestFlight/App Store distribution. Do not commit credentials or signing secrets.
- Record the real distribution URL in the README only after release. Do not mark this checklist complete from a green simulator run alone.
