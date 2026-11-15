# HeartSync demo

HeartSync is a local, shared-device couples check-in app. It has no remote accounts or partner sync. Both responses are visible to anyone using the app and are included in JSON backups.

1. **Home:** explain the single next action and the seven-day strip. Missing days have no assumed score. Fictional samples are explicitly labelled.
2. **Your check-in:** set energy/connection and write one reflection/intention. Save using the bottom control, then Continue together.
3. **Partner's check-in:** pass the device. The partner enters their own response and consents before saving. Show the shared conversation prompt; describe it as a rule-based invitation to listen, not AI or a clinical relationship score.
4. **Persistence:** return to Home, relaunch, reopen the shared check-in, then find the reflection in Moments. Edit your response and confirm the partner's response remains.
5. **Profile/data safety:** save the partner profile; export a JSON backup and store it safely. Explain that the clipboard is temporary and uninstalling can delete local data. Restore only after reviewing the destructive warning.

For a fictional demo, explicitly load Reset sample data in Profile. Never replace someone's real data just to recover a presentation. Unreadable saved data should lead to recovery, not silent sample substitution.

Use [the QA checklist](QA_CHECKLIST.md) for detailed assertions and the remaining manual Xcode/device checks. CI builds and tests on a simulator; that does not establish device/VoiceOver approval or a live release.
