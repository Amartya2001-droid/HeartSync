# HeartSync agent rules

1. Work on a branch. Open a pull request for every change. Never push directly to main.
2. Tests must pass before a PR is opened. If the repo has no tests, add a smoke test for what you changed.
3. Never commit secrets, API keys or credentials. Never invent credentials, licences or metrics.
4. Keep the README honest: what works, what is live, and the live URL.
5. At the end of the day, create (if it does not exist) the issue "10-day agent program — daily log" and post your report as a comment in this format:

   ## Day N — <repo>
   Did: <bullets, each with PR/commit link>
   Blocked on: <anything needing Amartya>
   Will do tomorrow: <bullets>
   Live status: <URL or "not live yet — blocked by …">

   Then stop. Do not start new work after the report.

Day 1 is TRIAGE: get oriented, get CI green, fix what's already open, and set up reporting. No new features. Work #6 before #4, with one PR per issue and a closing reference in each PR.

This is a SwiftUI iOS app. Linux cannot build SwiftUI/UIKit or run the iOS XCTest target. Run portable checks here, use macOS CI for simulator build/tests, and state what still needs Xcode/device review. Do not claim UI verification from static checks.
