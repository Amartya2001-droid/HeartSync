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

    var weeklyStory: String {
        if snapshot.relationshipPulse >= 4 && snapshot.streakDays >= 3 {
            return "This week looks steady. Consistency is doing the work, and the relationship is benefiting from small intentional moments."
        }

        if snapshot.relationshipPulse <= 3 {
            return "Connection has been softer this week. The app should frame this as awareness, not failure, and point the couple toward one practical reset."
        }

        return "You are in a rebuilding zone. Keep the streak alive and optimize for honesty over perfectly positive check-ins."
    }

    var latestCheckInDate: Date? {
        history.first?.date
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

    var weeklySummaryTitle: String {
        "HeartSync weekly summary"
    }

    var weeklySummaryText: String {
        let latestMoment = history.first?.note.isEmpty == false ? history.first?.note ?? "No recent moment captured." : "No recent moment captured."

        return """
        \(weeklySummaryTitle)

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
        """
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
}
