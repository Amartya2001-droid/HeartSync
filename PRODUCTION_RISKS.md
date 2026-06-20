# HeartSync Production Risks

## Current risks

- Test coverage exists for `HeartSyncStore`, but broader app/device validation is still pending
- No cloud sync or account model
- No analytics or crash reporting
- Final signing/device validation still pending outside this environment
- Cleared-history and first-run states still need real device validation
- Backup recovery now supports pasted JSON restore, but it still depends on users preserving exported backup text outside the app

## Important product decision

The largest unresolved product question is whether production means:

- a polished local-first journaling/check-in app
- or a shared couple experience with syncing

Those are different release tracks. The current codebase supports the first track much more than the second.

## Recommended mitigation this week

- Treat v1 as local-first unless product scope changes
- Validate on real devices
- Expand tests beyond the current store coverage before release
- Keep the release notes explicit about local data behavior
- Verify the backup-export status messaging matches real user expectations on device
