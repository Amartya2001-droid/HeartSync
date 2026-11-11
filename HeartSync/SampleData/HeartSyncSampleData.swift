import Foundation

/// Fictional fixtures shared by the existing demo reset and isolated previews.
enum HeartSyncSampleData {
    static let partner = PartnerProfile(
        name: "Jordan",
        milestone: "6-day reconnection sprint",
        supportFocus: "More intentional check-ins after busy workdays"
    )

    static let history: [DailyCheckIn] = [
        DailyCheckIn(date: Calendar.current.date(byAdding: .day, value: 0, to: .now) ?? .now, energy: 4, connection: 5, note: "We finally slowed down at dinner and actually asked each other how the day felt.", intention: "Take a short walk after work."),
        DailyCheckIn(date: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now, energy: 3, connection: 4, note: "Busy day, but we recovered well after naming what we each needed.", intention: "Send one thoughtful check-in text."),
        DailyCheckIn(date: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now, energy: 5, connection: 5, note: "Felt like a strong day. We laughed a lot and made time for planning together.", intention: "Protect our evening routine."),
        DailyCheckIn(date: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now, energy: 2, connection: 3, note: "Stress was high, but we were honest instead of avoiding it.", intention: "Ask for support earlier."),
        DailyCheckIn(date: Calendar.current.date(byAdding: .day, value: -4, to: .now) ?? .now, energy: 4, connection: 4, note: "Short check-in, but it helped us reset.", intention: "End the night with a 10-minute debrief.")
    ]

    static let demoPresets: [DemoPreset] = [
        DemoPreset(
            id: "reset-week",
            title: "Reset Week",
            partnerName: "Jordan",
            milestone: "6-day reconnection sprint",
            supportFocus: "More intentional check-ins after busy workdays"
        ),
        DemoPreset(
            id: "new-parents",
            title: "New Parents",
            partnerName: "Sam",
            milestone: "Finding our rhythm with the baby",
            supportFocus: "Reducing resentment and naming support needs earlier"
        ),
        DemoPreset(
            id: "long-distance",
            title: "Long Distance",
            partnerName: "Avery",
            milestone: "90-day long-distance stretch",
            supportFocus: "Creating more emotionally meaningful check-ins across time zones"
        )
    ]

}
