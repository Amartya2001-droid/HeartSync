# HeartSync launch marketing

November 26, 2026 · Day 1 · Review draft for the November 30 App Store readiness target

## 1. What the app does today

- HeartSync is an iOS app for daily check-ins for couples. Both people take turns on the same device. The repo describes local storage with no accounts, remote pairing, or cloud sync. The Profile tab contains local partner details.
- On Home, “Today, together” shows the next step. In Check-In, the first person rates their energy and how connected they feel, can add a reflection and an intention, and saves the day’s entry. They can return to edit it.
- In Together, the partner enters their own energy and connection ratings and can add a reflection and an intention. They agree to share on the device before saving. Both responses are visible in the app and included in JSON backups.
- After both respond, Together shows both perspectives and a conversation prompt selected by simple rules from their ratings. One possible prompt asks what they appreciated.
- Home shows recent activity and the last seven calendar days. Moments lets people revisit and search saved entries, including the partner’s perspective. Profile offers backup export and reviewed restore, local data controls, and opt-in fictional samples.
- **Unverified for launch.** A 60-second completion time, physical-device layout and VoiceOver review, and release availability. The source shows reflection and intention fields. Dedicated mood, daily needs, and appreciation fields are absent. Support, privacy policy and distribution URLs are unset in the current store-copy candidate.

Sources: [README][readme], [Check-In][checkin], [Together][together], [prompt rules][rules], [Home][home], [Moments][moments], [Profile][profile], [existing store copy][store].

## 2. Positioning

**For** couples who have already chosen each other and want an easy way to talk about how an ordinary day felt. **Out of scope** are singles looking to date, matchmaking, and browsing strangers’ dating profiles.

**After the match.** You already swiped right. Now stay in sync. HeartSync gives you and your partner a small daily ritual. Say how you feel, pass the phone, and find one thing to talk about together.

Three reasons to believe it:

1. **A simple place to start.** Rate your energy and how connected you feel. Add a reflection or an intention when you have something to say. [Check-In][checkin]
2. **Room for both people.** Pass the same phone to your partner. They add their own perspective and agree to share it before saving. [Together][together]
3. **Something to talk about.** Once both check-ins are saved, the app offers a conversation prompt based on the ratings. [Together][together] · [Prompt rules][rules]

## 3. App Store listing draft

| Field | Proposed copy |
| --- | --- |
| Title | HeartSync |
| Subtitle | Daily check-ins for couples |
| Keywords | relationship,journal,reflection,intention,connection,partner,ritual,energy |
| What’s New | First release of HeartSync. Take turns checking in on one device, get a conversation prompt after you both respond, and revisit saved check-ins in Moments. |

### Full description

HeartSync is a daily check-in for couples who’ve already found each other. Take a small pause together, even on an ordinary day.

Start by rating your energy and how connected you feel. If you like, add a short reflection about your day or write down one intention. When your partner is ready, pass them the phone so they can add their own check-in.

Once you’ve both responded, see both perspectives and get a question to talk through together. Revisit saved check-ins in Moments or see the days you checked in on Home.

You take turns on one device. Check-ins are stored locally and are visible to anyone using the app on that device. If you export a backup, it includes both people’s responses.

Sources: [Check-In][checkin], [Together][together], [Home][home], [Moments][moments], [Profile][profile], [existing store copy][store]. The What’s New draft assumes an initial release. Amartya to confirm release metadata and whether this field is needed.

## 4. App Store screenshot plan

Use fictional responses on the same device across the sequence. Amartya to capture all six on a real iPhone, review legibility, and confirm submission sizes. Existing simulator images can guide framing.

| Order | In-app state to capture | Overlay caption | Real device capture |
| --- | --- | --- | --- |
| 1 | Welcome, with the brand lockup and shared-device disclosure visible. [Welcome][welcome] | A daily check-in for couples | Amartya |
| 2 | Home, “Today, together” card before today’s first check-in. Show “Start today’s check-in.” [Home][home] · [Action labels][overview] | Make a little time for each other | Amartya |
| 3 | Check-In, framed around energy and connection sliders. [Check-In][checkin] | Share how you feel today | Amartya |
| 4 | Together, “Pass the device” with the partner’s input and consent toggle. [Together][together] | Pass the phone to your partner | Amartya |
| 5 | Together after both save, positioned to show the question under “A conversation, not a score.” [Together][together] | Find one thing to talk about | Amartya |
| 6 | Moments with a saved fictional entry and its partner response visible. [Moments][moments] | Look back on your check-ins | Amartya |

## 5. Branding and launch assets for Issue #1

**Icon direction.** Keep the existing paired-heart candidate. Two interlocking outlines stand for two perspectives. Use dark burgundy on warm peach with muted coral as an accent. Review the silhouette at home-screen size, keeping the mark centered with room for the iOS mask. Amartya to approve the current candidate. [Asset guide][assets] · [Issue #1](https://github.com/Amartya2001-droid/HeartSync/issues/1)

| Graphic | Headline | Supporting line | Visual direction |
| --- | --- | --- | --- |
| Launch card for LinkedIn and X | After the match | A daily check-in for couples who’ve already found each other. | Paired-heart mark and HeartSync wordmark on peach. |
| Instagram carousel, card 1 | You already swiped right. Now stay in sync. | A small pause, together. | Paired-heart mark with the HeartSync wordmark. |
| Instagram carousel, card 2 | Share how you feel | Rate your energy and how connected you feel today. | Real Check-In capture from screenshot 3. |
| Instagram carousel, card 3 | Pass the phone | Give your partner room to share how their day felt. | Real Together capture from screenshot 4. |
| Instagram carousel, card 4 | Take one question with you | When you’ve both checked in, HeartSync gives you something to talk about. | Real Together capture from screenshot 5. |

Hold availability language and download links until there’s a verified live destination.

## 6. Ten short launch posts

1. **LinkedIn** · A match is a beginning. HeartSync is for the ordinary days that come after. Take turns on one phone, share how you’re feeling, and start a conversation.
2. **LinkedIn** · We built HeartSync for couples who’ve already chosen each other. Start with a daily check-in about energy and connection. Then pass the phone and hear how the day felt to your partner.
3. **LinkedIn** · Some evenings, “How was your day?” gets you as far as “Fine.” HeartSync starts with two ratings and gives you room for a reflection if there’s more to say.
4. **X** · You already swiped right. Now stay in sync. HeartSync is a daily check-in for the two of you, on one phone.
5. **X** · How’s your energy? How connected do you feel? HeartSync gives couples two simple places to start.
6. **X** · Check in. Pass the phone. When you’ve both shared how the day felt, HeartSync gives you a question to talk through together.
7. **X** · Two people can have very different Tuesdays. HeartSync gives each of you room to say how yours felt.
8. **Instagram** · A small pause, together. Share how you feel, pass the phone, and make time to hear each other.
9. **Instagram** · Some days all you have is a sentence. Add a reflection or an intention to your HeartSync check-in, then give your partner a turn.
10. **Instagram** · Ordinary days are worth remembering. Open Moments to look back on the check-ins you’ve saved together.

[readme]: https://github.com/Amartya2001-droid/HeartSync/blob/0f8620afbda204243da06e4a103465f5706f4aef/README.md
[checkin]: https://github.com/Amartya2001-droid/HeartSync/blob/0f8620afbda204243da06e4a103465f5706f4aef/HeartSync/Screens/CheckInView.swift
[together]: https://github.com/Amartya2001-droid/HeartSync/blob/0f8620afbda204243da06e4a103465f5706f4aef/HeartSync/Screens/CoupleCheckInView.swift
[rules]: https://github.com/Amartya2001-droid/HeartSync/blob/0f8620afbda204243da06e4a103465f5706f4aef/HeartSync/Models/CoupleCheckIn.swift
[home]: https://github.com/Amartya2001-droid/HeartSync/blob/0f8620afbda204243da06e4a103465f5706f4aef/HeartSync/Screens/DashboardView.swift
[moments]: https://github.com/Amartya2001-droid/HeartSync/blob/0f8620afbda204243da06e4a103465f5706f4aef/HeartSync/Screens/JournalView.swift
[profile]: https://github.com/Amartya2001-droid/HeartSync/blob/0f8620afbda204243da06e4a103465f5706f4aef/HeartSync/Screens/SettingsView.swift
[store]: https://github.com/Amartya2001-droid/HeartSync/blob/0f8620afbda204243da06e4a103465f5706f4aef/release/APP_STORE_COPY.json
[welcome]: https://github.com/Amartya2001-droid/HeartSync/blob/0f8620afbda204243da06e4a103465f5706f4aef/HeartSync/Screens/OnboardingSheetView.swift
[overview]: https://github.com/Amartya2001-droid/HeartSync/blob/0f8620afbda204243da06e4a103465f5706f4aef/HeartSync/Models/HomeOverview.swift
[assets]: https://github.com/Amartya2001-droid/HeartSync/blob/0f8620afbda204243da06e4a103465f5706f4aef/release/ASSET_GUIDE.md
