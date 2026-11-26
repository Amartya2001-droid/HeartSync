# HeartSync QA checklist

## Repeatable simulator coverage

Run the shared `HeartSync` scheme with `xcodebuild test` (the README has the command). GitHub Actions runs the same scheme on an available iPhone simulator, without signing. The suite checks:

- First launch enters Check-In without a second empty-history sheet.
- Home leads to a saved reflection, partner consent is required, both perspectives produce a shared summary, and relaunch preserves the pair.
- Empty/sample Home primary actions remain reachable and within the screen at accessibility text size. Captures are exported for inspection.
- Cancelling clear-history preserves the shared check-in; a confirmed clear followed by a copied JSON restore brings both perspectives back after relaunch. Restore feedback remains beside the restore controls.
- Unreadable-state recovery disables profile/preset/sample/clear actions. An explicitly confirmed fresh start persists an empty state; unit tests verify unreadable bytes are retained and blocked actions do not mutate the recovery state.
- Profile accepts a valid name, explains an oversized name without claiming success, and relaunch retains the last saved name.
- Unit regressions cover profile rollback, unreadable-state backup rejection, calendar-week bounds, supported ritual symbols, backup validation, migration and both-response persistence.

CI artifacts: `ios-test-results` contains the xcresult bundle and exported attachment manifest; `home-screenshots` contains PNG captures. A passing test is evidence for its assertions, not blanket accessibility or release approval.

## Short demo / acceptance pass

1. Use a clean install or a separate simulator. Real installs start empty. Onboarding → Start checking in → enter your ratings, reflection and intention → Save → Continue together.
2. Hand the device to a consenting partner. Confirm saving is disabled before consent. Add their response, consent and save. Read the conversation prompt together.
3. Close Together. Home should offer the shared check-in. Relaunch and confirm both perspectives and your reflection remain.
4. Edit your reflection; verify the partner's response remains. Open Moments and search a word from either response.
5. In Profile, save a real partner name and relaunch. An empty/over-limit name must explain that it was not saved.
6. Copy a JSON backup and store it outside the clipboard before any destructive action. Review it: it contains both people's responses. Clear history only after confirming the warning, then restore the valid backup. Invalid JSON must leave the current data unchanged.
7. Use Reset sample data only for an explicitly fictional demo. Home must label it. Clear it before entering real check-ins.

## Backup file regression coverage

- The bounded reader rejects folders, empty/binary data and files over 5 MB. Valid text with an invalid schema cannot enter the restore flow.
- A real temporary-file round trip restores both perspectives with the existing JSON format.
- Preparing/cancelling a file export does not mark it current; the completion receipt must match current data. A stale snapshot or unreadable active state cannot claim a current backup.
- Profile's file export/import actions are reachable in the simulator. No automated test is claimed to have operated an external Files/iCloud provider.

- Read-only verification re-reads the selected URL for every request and compares logical state. Unit cases cover match, known earlier export, unknown-origin mismatch, file replacement, invalid/oversized/unreadable input, recovery, profile/partner/sample changes, format/order independence, and result invalidation after local edits. No export marker or persistent data may change.
- Pending manual verification: save a fictional backup, select Verify backup file, confirm a match; edit local data and select the file again; confirm stale only with this session's successful export evidence, otherwise unknown-age mismatch. Replace/delete the file and reselect it to confirm it is re-read. Cancel the picker and check saved data and restore preview remain unchanged. Never auto-restore.

## Amartya's manual checks — pending

These were not performed in this Linux environment:

- VoiceOver reading order, labels, rotor actions and consent controls on all four screens.
- Full small-phone/iPad and landscape layout, large text beyond the specific automated Home assertions, keyboard dismissal and interaction throughout the app.
- Physical-device clipboard permission prompts, share sheets, backup transfer/storage and relaunch after force quit. For file backups: save to an actual local/provider location, cancel export/import, reopen the saved file for preview, confirm restore, and verify editing during an open save panel is not marked backed up by an older file. Check security-scoped provider permissions and unavailable-provider errors.
- App signing, provisioning, privacy/release decisions, TestFlight/App Store distribution.

Do not call these checks passed from CI screenshots alone. The app is not live until a real distribution URL exists.

## Handoff completion gate

A pushed branch, a green run, and a drafted report are not completion. Before ending: confirm tests on the exact head, create the PR, post the daily-log report with its link, and confirm the comment call succeeded. If CI fails, fix the failure and repeat the gate; never publish a passing claim for a failed run.
