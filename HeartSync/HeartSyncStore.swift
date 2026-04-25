import Foundation
import SwiftUI
import UIKit

struct PartnerProfile: Codable {
    var name: String
    var milestone: String
    var supportFocus: String
}

struct DailyCheckIn: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    var energy: Int
    var connection: Int
    var note: String
    var intention: String

    init(
        id: UUID = UUID(),
        date: Date,
        energy: Int,
        connection: Int,
        note: String,
        intention: String
    ) {
        self.id = id
        self.date = date
        self.energy = energy
        self.connection = connection
        self.note = note
        self.intention = intention
    }
}

struct HeartSyncSnapshot {
    let relationshipPulse: Int
    let weeklyAverageEnergy: Int
    let weeklyAverageConnection: Int
    let streakDays: Int
    let latestCheckIn: DailyCheckIn?
}

struct DemoPreset: Identifiable, Hashable {
    let id: String
    let title: String
    let partnerName: String
    let milestone: String
    let supportFocus: String
}

struct PromptSuggestion: Identifiable, Hashable {
    let id: String
    let text: String
}

struct DemoReadinessItem: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let isReady: Bool
}

struct RitualRecommendation: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
}

@MainActor
final class HeartSyncStore: ObservableObject {
    @Published var partner: PartnerProfile
    @Published var todayEnergy: Double
    @Published var todayConnection: Double
    @Published var todayNote: String
    @Published var todayIntention: String
    @Published private(set) var history: [DailyCheckIn]

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum StorageKeys {
        static let partner = "heartsync.partner"
        static let history = "heartsync.history"
        static let draftEnergy = "heartsync.draft.energy"
        static let draftConnection = "heartsync.draft.connection"
        static let draftNote = "heartsync.draft.note"
        static let draftIntention = "heartsync.draft.intention"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if let data = defaults.data(forKey: StorageKeys.partner),
           let storedPartner = try? decoder.decode(PartnerProfile.self, from: data) {
            partner = storedPartner
        } else {
            partner = PartnerProfile(
                name: "Jordan",
                milestone: "6-day reconnection sprint",
                supportFocus: "More intentional check-ins after busy workdays"
            )
        }

        let initialHistory: [DailyCheckIn]
        if let data = defaults.data(forKey: StorageKeys.history),
           let storedHistory = try? decoder.decode([DailyCheckIn].self, from: data) {
            initialHistory = storedHistory.sorted { $0.date > $1.date }
        } else {
            initialHistory = Self.sampleHistory
        }

        history = initialHistory

        let latest = initialHistory.first
        todayEnergy = defaults.object(forKey: StorageKeys.draftEnergy) as? Double ?? Double(latest?.energy ?? 4)
        todayConnection = defaults.object(forKey: StorageKeys.draftConnection) as? Double ?? Double(latest?.connection ?? 4)
        todayNote = defaults.string(forKey: StorageKeys.draftNote) ?? ""
        todayIntention = defaults.string(forKey: StorageKeys.draftIntention) ?? "Protect 20 minutes for a no-phone check-in tonight."
    }

    var snapshot: HeartSyncSnapshot {
        let lastSeven = Array(history.prefix(7))
        let pulse = lastSeven.isEmpty ? 0 : Int(lastSeven.map(\.connection).reduce(0, +) / lastSeven.count)
        let energyAverage = lastSeven.isEmpty ? 0 : Int(lastSeven.map(\.energy).reduce(0, +) / lastSeven.count)
        let connectionAverage = lastSeven.isEmpty ? 0 : Int(lastSeven.map(\.connection).reduce(0, +) / lastSeven.count)

        return HeartSyncSnapshot(
            relationshipPulse: pulse,
            weeklyAverageEnergy: energyAverage,
            weeklyAverageConnection: connectionAverage,
            streakDays: currentStreakDays(),
            latestCheckIn: history.first
        )
    }

    var recentMoments: [DailyCheckIn] {
        Array(history.prefix(5))
    }

    var recommendedAction: String {
        if snapshot.weeklyAverageConnection <= 3 {
            return "Prioritize a 10-minute repair conversation tonight before distractions take over."
        }

        if snapshot.weeklyAverageEnergy <= 3 {
            return "Keep the check-in gentle today and ask what support would feel light, not heavy."
        }

        return "You have momentum. Protect one intentional ritual tonight so the good stretch keeps compounding."
    }

    var recommendedRituals: [RitualRecommendation] {
        if snapshot.weeklyAverageConnection <= 3 {
            return [
                RitualRecommendation(id: "repair", title: "Repair first", detail: "Name one thing that felt hard without trying to solve everything.", symbol: "wrench.and.screwdriver.fill"),
                RitualRecommendation(id: "ask", title: "Ask for support", detail: "Each person names one concrete support request for tomorrow.", symbol: "bubble.left.and.bubble.right.fill"),
                RitualRecommendation(id: "close", title: "End softly", detail: "Close with one appreciation so the conversation does not end on tension.", symbol: "heart.fill")
            ]
        }

        if snapshot.weeklyAverageEnergy <= 3 {
            return [
                RitualRecommendation(id: "light", title: "Keep it light", detail: "Choose a short check-in instead of a heavy conversation.", symbol: "feather.fill"),
                RitualRecommendation(id: "rest", title: "Protect rest", detail: "Make the supportive move the one that reduces effort tonight.", symbol: "moon.zzz.fill"),
                RitualRecommendation(id: "tomorrow", title: "Plan one thing", detail: "Pick a tiny tomorrow action while energy is still low.", symbol: "calendar.badge.clock")
            ]
        }

        return [
            RitualRecommendation(id: "celebrate", title: "Notice the win", detail: "Name what worked this week so it becomes repeatable.", symbol: "sparkles"),
            RitualRecommendation(id: "walk", title: "Move together", detail: "Take a short walk and ask one better question.", symbol: "figure.walk"),
            RitualRecommendation(id: "protect", title: "Protect the rhythm", detail: "Keep one phone-free moment on the calendar tonight.", symbol: "shield.lefthalf.filled")
        ]
    }

    var weeklyStory: String {
        if snapshot.relationshipPulse >= 4 && snapshot.streakDays >= 3 {
            return "This week looks steady. Consistency is doing the work, and the relationship is benefiting from small intentional moments."
        }

        if snapshot.relationshipPulse <= 3 {
            return "Connection has been softer this week. The app should frame this as awareness, not failure, and point the couple toward one practical reset."
        }

        return "You are in a rebuilding zone. Keep the streak alive and optimize for honesty over perfectly positive check-ins."
    }

    var connectionTrendTitle: String {
        switch connectionTrendDelta {
        case 1...:
            return "Connection is rising"
        case ..<0:
            return "Connection needs care"
        default:
            return "Connection is steady"
        }
    }

    var connectionTrendMessage: String {
        guard history.count >= 4 else {
            return "Keep logging a few more check-ins and HeartSync will start comparing patterns over time."
        }

        switch connectionTrendDelta {
        case 1...:
            return "Recent check-ins are trending stronger than the previous stretch. Capture what helped so it can become repeatable."
        case ..<0:
            return "Recent check-ins are softer than the previous stretch. Use today’s intention to lower the emotional load."
        default:
            return "The pattern is stable right now. A small consistent ritual is the best next move."
        }
    }

    private var connectionTrendDelta: Int {
        let recent = Array(history.prefix(3))
        let previous = Array(history.dropFirst(3).prefix(3))
        guard !recent.isEmpty, !previous.isEmpty else { return 0 }

        let recentAverage = recent.map(\.connection).reduce(0, +) / recent.count
        let previousAverage = previous.map(\.connection).reduce(0, +) / previous.count
        return recentAverage - previousAverage
    }

    var latestCheckInDate: Date? {
        history.first?.date
    }

    func relativeDayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        return date.formatted(.dateTime.weekday(.wide))
    }

    func calendarDateLabel(for date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    func dateContextLabel(for date: Date) -> String {
        "\(relativeDayLabel(for: date)) • \(calendarDateLabel(for: date))"
    }

    var todayCheckIn: DailyCheckIn? {
        let today = Calendar.current.startOfDay(for: .now)
        return history.first {
            Calendar.current.isDate(Calendar.current.startOfDay(for: $0.date), inSameDayAs: today)
        }
    }

    var hasCompletedTodayCheckIn: Bool {
        todayCheckIn != nil
    }

    var todayStatusTitle: String {
        hasCompletedTodayCheckIn ? "Today's check-in is in" : "Today's check-in is still open"
    }

    var todayStatusMessage: String {
        guard let todayCheckIn else {
            return "A 60-second reflection is enough to keep the relationship pulse current."
        }

        if todayCheckIn.note.isEmpty {
            return "You logged today's emotional state. Add a note later if more context comes up."
        }

        return todayCheckIn.note
    }

    var draftCoachingTitle: String {
        let energy = Int(todayEnergy.rounded())
        let connection = Int(todayConnection.rounded())

        switch (energy, connection) {
        case let (energy, _) where energy <= 2:
            return "Keep this one gentle"
        case let (_, connection) where connection <= 2:
            return "Name the distance early"
        case (4...5, 4...5):
            return "Turn momentum into a ritual"
        default:
            return "Choose one small next step"
        }
    }

    var draftCoachingMessage: String {
        let energy = Int(todayEnergy.rounded())
        let connection = Int(todayConnection.rounded())

        switch (energy, connection) {
        case let (energy, _) where energy <= 2:
            return "Low energy days are not the time for a perfect conversation. Aim for one clear ask and one kind check-in."
        case let (_, connection) where connection <= 2:
            return "Connection feels lower today, so make the intention concrete: when, where, and what support would help."
        case (4...5, 4...5):
            return "This is a good day to notice what worked and protect it as a repeatable rhythm."
        default:
            return "Use the note to capture what is true, then set an intention that feels doable tonight."
        }
    }

    var weeklySummaryTitle: String {
        "HeartSync weekly summary"
    }

    var weeklyDateRangeLabel: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        return "\(start.formatted(.dateTime.month(.abbreviated).day())) - \(today.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var exportGeneratedAtLabel: String {
        Date.now.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }

    var strongestMomentSummary: String {
        guard let strongest = history.max(by: compareMomentsForStrength) else {
            return "No standout moment captured yet."
        }

        return strongest.note.isEmpty
            ? "A higher-connection day was logged without a note."
            : strongest.note
    }

    var needsCareSummary: String {
        guard let lowest = history.min(by: compareMomentsForStrength) else {
            return "No lower-connection moment captured yet."
        }

        return lowest.note.isEmpty
            ? "A lower-connection day was logged without a note."
            : lowest.note
    }

    var weeklySummaryText: String {
        let latestMoment = history.first?.note.isEmpty == false ? history.first?.note ?? "No recent moment captured." : "No recent moment captured."

        return """
        \(weeklySummaryTitle)
        Range: \(weeklyDateRangeLabel)
        Exported: \(exportGeneratedAtLabel)

        Partner: \(partner.name)
        Milestone: \(partner.milestone)
        Support focus: \(partner.supportFocus)

        Relationship pulse: \(snapshot.relationshipPulse)/5
        Average energy: \(snapshot.weeklyAverageEnergy)/5
        Average connection: \(snapshot.weeklyAverageConnection)/5
        Check-in streak: \(snapshot.streakDays) day(s)

        Weekly story:
        \(weeklyStory)

        Recommended next step:
        \(recommendedAction)

        Latest moment:
        \(latestMoment)

        What helped most:
        \(strongestMomentSummary)

        What may need care:
        \(needsCareSummary)
        """
    }

    var presenterTalkTrack: String {
        """
        HeartSync demo talk track
        Exported: \(exportGeneratedAtLabel)

        HeartSync is a calm daily relationship check-in app. The MVP loop is simple: log energy and connection, capture one honest reflection, set one intention, and use the dashboard to understand the relationship pulse.

        Today’s demo flow:
        1. Start on Home and explain pulse, streak, trend, and tonight’s ritual plan.
        2. Open Check-In and show the coaching hint plus prompt suggestions.
        3. Save a check-in, then use Moments to search or share an individual entry.
        4. End in Profile with demo readiness, presets, and weekly summary sharing.

        Current story:
        \(weeklyStory)

        Recommended close:
        \(recommendedAction)
        """
    }

    var latestMomentText: String {
        guard let latest = history.first else {
            return "No HeartSync moment has been captured yet."
        }

        return """
        HeartSync latest moment
        Exported: \(exportGeneratedAtLabel)

        Date: \(dateContextLabel(for: latest.date))
        Energy: \(latest.energy)/5
        Connection: \(latest.connection)/5

        Note:
        \(latest.note.isEmpty ? "No note captured." : latest.note)

        Intention:
        \(latest.intention.isEmpty ? "No intention captured." : latest.intention)
        """
    }

    var fullHistoryText: String {
        guard !history.isEmpty else {
            return "No HeartSync moments have been captured yet."
        }

        let entries = history.map { entry in
            """
            \(dateContextLabel(for: entry.date))
            Energy: \(entry.energy)/5
            Connection: \(entry.connection)/5
            Note: \(entry.note.isEmpty ? "No note captured." : entry.note)
            Intention: \(entry.intention.isEmpty ? "No intention captured." : entry.intention)
            """
        }
        .joined(separator: "\n\n---\n\n")

        return """
        HeartSync moments export
        Exported: \(exportGeneratedAtLabel)

        Partner: \(partner.name)
        Milestone: \(partner.milestone)

        \(entries)
        """
    }

    var demoReadinessItems: [DemoReadinessItem] {
        [
            DemoReadinessItem(
                id: "profile",
                title: "Profile is personalized",
                detail: "Partner name, milestone, and support focus are ready for the story.",
                isReady: !partner.name.isEmpty && !partner.milestone.isEmpty && !partner.supportFocus.isEmpty
            ),
            DemoReadinessItem(
                id: "history",
                title: "Moments have sample history",
                detail: "The dashboard and Moments tab have enough data to show patterns.",
                isReady: history.count >= 3
            ),
            DemoReadinessItem(
                id: "today",
                title: "Today has a check-in",
                detail: "A current entry makes the Home and Check-In states feel live.",
                isReady: hasCompletedTodayCheckIn
            ),
            DemoReadinessItem(
                id: "summary",
                title: "Weekly summary is shareable",
                detail: "The presenter can share or copy a concise relationship snapshot.",
                isReady: !weeklySummaryText.isEmpty
            )
        ]
    }

    var demoReadinessSummary: String {
        let readyCount = demoReadinessItems.filter(\.isReady).count
        return "\(readyCount) of \(demoReadinessItems.count) demo checks ready"
    }

    var isDemoReady: Bool {
        demoReadinessItems.allSatisfy(\.isReady)
    }

    var notePromptSuggestions: [PromptSuggestion] {
        [
            PromptSuggestion(id: "repair", text: "We handled stress better once we said what we needed."),
            PromptSuggestion(id: "ritual", text: "A small ritual helped us feel more like a team tonight."),
            PromptSuggestion(id: "drift", text: "We felt a little off today and need a calmer reset tomorrow.")
        ]
    }

    var intentionSuggestions: [PromptSuggestion] {
        [
            PromptSuggestion(id: "walk", text: "Take a 10-minute walk together after work."),
            PromptSuggestion(id: "phones", text: "Protect 20 phone-free minutes tonight."),
            PromptSuggestion(id: "checkin", text: "Ask one better question before the day ends.")
        ]
    }

    func applyNoteSuggestion(_ suggestion: PromptSuggestion) {
        todayNote = suggestion.text
        saveDraft()
    }

    func applyIntentionSuggestion(_ suggestion: PromptSuggestion) {
        todayIntention = suggestion.text
        saveDraft()
    }

    func copyWeeklySummaryToClipboard() {
        UIPasteboard.general.string = weeklySummaryText
    }

    func copyPresenterTalkTrackToClipboard() {
        UIPasteboard.general.string = presenterTalkTrack
    }

    func copyLatestMomentToClipboard() {
        UIPasteboard.general.string = latestMomentText
    }

    func copyFullHistoryToClipboard() {
        UIPasteboard.general.string = fullHistoryText
    }

    func loadTodayCheckInIntoDraft() {
        guard let todayCheckIn else { return }
        todayEnergy = Double(todayCheckIn.energy)
        todayConnection = Double(todayCheckIn.connection)
        todayNote = todayCheckIn.note
        todayIntention = todayCheckIn.intention
        saveDraft()
    }

    func clearDraft() {
        todayEnergy = 3
        todayConnection = 3
        todayNote = ""
        todayIntention = ""
        saveDraft()
    }

    func saveDraft() {
        defaults.set(todayEnergy, forKey: StorageKeys.draftEnergy)
        defaults.set(todayConnection, forKey: StorageKeys.draftConnection)
        defaults.set(todayNote, forKey: StorageKeys.draftNote)
        defaults.set(todayIntention, forKey: StorageKeys.draftIntention)
    }

    func submitCheckIn() {
        let today = Calendar.current.startOfDay(for: .now)
        let newCheckIn = DailyCheckIn(
            date: today,
            energy: Int(todayEnergy.rounded()),
            connection: Int(todayConnection.rounded()),
            note: todayNote.trimmingCharacters(in: .whitespacesAndNewlines),
            intention: todayIntention.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        history.removeAll { Calendar.current.isDate($0.date, inSameDayAs: today) }
        history.insert(newCheckIn, at: 0)
        persistHistory()

        todayNote = ""
        todayIntention = "Protect 20 minutes for a no-phone check-in tonight."
        saveDraft()
    }

    func deleteCheckIns(at offsets: IndexSet, from entries: [DailyCheckIn]) {
        let idsToDelete = offsets.map { entries[$0].id }
        history.removeAll { idsToDelete.contains($0.id) }
        persistHistory()
    }

    func updatePartner(name: String, milestone: String, supportFocus: String) {
        partner = PartnerProfile(name: name, milestone: milestone, supportFocus: supportFocus)
        persistPartner()
    }

    func applyPreset(_ preset: DemoPreset) {
        partner = PartnerProfile(
            name: preset.partnerName,
            milestone: preset.milestone,
            supportFocus: preset.supportFocus
        )
        persistPartner()
    }

    func resetDemoData() {
        partner = PartnerProfile(
            name: "Jordan",
            milestone: "6-day reconnection sprint",
            supportFocus: "More intentional check-ins after busy workdays"
        )
        history = Self.sampleHistory
        todayEnergy = Double(Self.sampleHistory.first?.energy ?? 4)
        todayConnection = Double(Self.sampleHistory.first?.connection ?? 4)
        todayNote = ""
        todayIntention = "Protect 20 minutes for a no-phone check-in tonight."
        persistPartner()
        persistHistory()
        saveDraft()
    }

    private func currentStreakDays() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var cursor = calendar.startOfDay(for: .now)

        for entry in history.sorted(by: { $0.date > $1.date }) {
            let entryDay = calendar.startOfDay(for: entry.date)
            if calendar.isDate(entryDay, inSameDayAs: cursor) {
                streak += 1
                guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                cursor = previous
            } else if entryDay < cursor {
                break
            }
        }

        return streak
    }

    private func persistHistory() {
        if let data = try? encoder.encode(history) {
            defaults.set(data, forKey: StorageKeys.history)
        }
    }

    private func persistPartner() {
        if let data = try? encoder.encode(partner) {
            defaults.set(data, forKey: StorageKeys.partner)
        }
    }

    private static let sampleHistory: [DailyCheckIn] = [
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

    private func compareMomentsForStrength(lhs: DailyCheckIn, rhs: DailyCheckIn) -> Bool {
        if lhs.connection == rhs.connection {
            return lhs.energy < rhs.energy
        }

        return lhs.connection < rhs.connection
    }
}
