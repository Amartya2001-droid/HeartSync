import Foundation
import SwiftUI
import UIKit

@MainActor
final class HeartSyncStore: ObservableObject {
    @Published var partner: PartnerProfile
    @Published var todayEnergy: Double { didSet { saveDraft() } }
    @Published var todayConnection: Double { didSet { saveDraft() } }
    @Published var todayNote: String { didSet { saveDraft() } }
    @Published var todayIntention: String { didSet { saveDraft() } }
    @Published private(set) var history: [DailyCheckIn]

    @Published private(set) var containsSampleData = false
    @Published private(set) var recoveryMessage: String?
    private var isApplyingState = false

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let defaultIntentionText = "Protect 20 minutes for a no-phone check-in tonight."

    private enum StorageKeys {
        static let state = "heartsync.state.v1"
        static let unreadableState = "heartsync.recovery.unreadable"
        static let partner = "heartsync.partner"
        static let history = "heartsync.history"
        static let draftEnergy = "heartsync.draft.energy"
        static let draftConnection = "heartsync.draft.connection"
        static let draftNote = "heartsync.draft.note"
        static let draftIntention = "heartsync.draft.intention"
        static let dataUpdatedAt = "heartsync.data.updatedAt"
        static let lastBackupExportAt = "heartsync.backup.lastExportedAt"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        partner = PartnerProfile(name: "Your partner", milestone: "Our daily check-in", supportFocus: "Listen and make time for each other")
        history = []
        todayEnergy = 3
        todayConnection = 3
        todayNote = ""
        todayIntention = defaultIntentionText

        if let data = defaults.data(forKey: StorageKeys.state) {
            if let state = try? decoder.decode(StoredHeartSyncState.self, from: data), state.isValid {
                apply(state)
            } else {
                recoveryMessage = "Saved data could not be read. It has not been replaced. Restore a valid JSON backup in Profile, or choose Start fresh to keep an unreadable copy and begin again."
            }
        } else if defaults.object(forKey: StorageKeys.history) != nil || defaults.object(forKey: StorageKeys.partner) != nil {
            // Migrate the previous unversioned keys without substituting fictional history.
            let oldHistory = defaults.data(forKey: StorageKeys.history).flatMap { try? decoder.decode([DailyCheckIn].self, from: $0) }
            let oldPartner = defaults.data(forKey: StorageKeys.partner).flatMap { try? decoder.decode(PartnerProfile.self, from: $0) }
            let draft = CheckInDraft(
                energy: defaults.object(forKey: StorageKeys.draftEnergy) as? Double ?? 3,
                connection: defaults.object(forKey: StorageKeys.draftConnection) as? Double ?? 3,
                note: defaults.string(forKey: StorageKeys.draftNote) ?? "",
                intention: defaults.string(forKey: StorageKeys.draftIntention) ?? defaultIntentionText
            )
            let legacy = StoredHeartSyncState(partner: oldPartner ?? partner, history: oldHistory ?? [], draft: draft, containsSampleData: false)
            if (defaults.object(forKey: StorageKeys.history) == nil || oldHistory != nil),
               (defaults.object(forKey: StorageKeys.partner) == nil || oldPartner != nil), legacy.isValid {
                apply(legacy)
                persistState()
            } else {
                recoveryMessage = "Existing local data could not be migrated safely. Restore a backup in Profile or choose Start fresh. The original keys have not been replaced."
            }
        }
    }

    private var currentState: StoredHeartSyncState {
        StoredHeartSyncState(partner: partner, history: history,
            draft: CheckInDraft(energy: todayEnergy, connection: todayConnection, note: todayNote, intention: todayIntention),
            containsSampleData: containsSampleData)
    }

    private func apply(_ state: StoredHeartSyncState) {
        isApplyingState = true
        partner = state.partner
        history = state.history.sorted { $0.date > $1.date }
        todayEnergy = state.draft.energy
        todayConnection = state.draft.connection
        todayNote = state.draft.note
        todayIntention = state.draft.intention
        containsSampleData = state.containsSampleData
        isApplyingState = false
    }

    private func preserveUnreadableState() {
        if recoveryMessage != nil, let data = defaults.data(forKey: StorageKeys.state) {
            defaults.set(data, forKey: StorageKeys.unreadableState)
        }
    }

    func startFreshAfterRecovery() {
        preserveUnreadableState()
        recoveryMessage = nil
        apply(StoredHeartSyncState(
            partner: PartnerProfile(name: "Your partner", milestone: "Our daily check-in", supportFocus: "Listen and make time for each other"),
            history: [], draft: CheckInDraft(), containsSampleData: false))
        persistState()
    }

    private func persistState() {
        guard !isApplyingState, recoveryMessage == nil else { return }
        guard currentState.isValid, let data = try? encoder.encode(currentState) else { return }
        defaults.set(data, forKey: StorageKeys.state)
        markDataUpdated()
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

    var hasHistory: Bool {
        !history.isEmpty
    }

    private var dataUpdatedAt: Date? {
        defaults.object(forKey: StorageKeys.dataUpdatedAt) as? Date
    }

    private var lastBackupExportAt: Date? {
        defaults.object(forKey: StorageKeys.lastBackupExportAt) as? Date
    }

    var hasCurrentBackupExport: Bool {
        guard let dataUpdatedAt else { return lastBackupExportAt != nil }
        guard let lastBackupExportAt else { return false }
        return lastBackupExportAt >= dataUpdatedAt
    }

    var lastBackupExportLabel: String {
        guard let lastBackupExportAt else {
            return "No JSON backup exported yet"
        }

        return "Last backup export: \(lastBackupExportAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))"
    }

    var exportStatus: ExportStatusSnapshot {
        guard hasHistory else {
            return ExportStatusSnapshot(
                title: "Backup export is optional right now",
                detail: "History is empty, so a JSON backup is not urgent yet. Export after you rebuild sample data or log fresh moments.",
                isCurrent: true
            )
        }

        if hasCurrentBackupExport {
            return ExportStatusSnapshot(
                title: "Backup export is current",
                detail: "The latest local profile, draft, and moments have been captured in a JSON export.",
                isCurrent: true
            )
        }

        if lastBackupExportAt == nil {
            return ExportStatusSnapshot(
                title: "Backup export recommended",
                detail: "This device has local-only HeartSync data, but no JSON backup has been copied yet.",
                isCurrent: false
            )
        }

        return ExportStatusSnapshot(
            title: "Backup export needs refresh",
            detail: "Local data changed after the last JSON backup. Export again before handoff or release review.",
            isCurrent: false
        )
    }

    var recommendedAction: String {
        if history.isEmpty {
            return "Start with one check-in so HeartSync has a real signal to work from."
        }

        if snapshot.weeklyAverageConnection <= 3 {
            return "Prioritize a 10-minute repair conversation tonight before distractions take over."
        }

        if snapshot.weeklyAverageEnergy <= 3 {
            return "Keep the check-in gentle today and ask what support would feel light, not heavy."
        }

        return "You have momentum. Protect one intentional ritual tonight so the good stretch keeps compounding."
    }

    var recommendedRituals: [RitualRecommendation] {
        if history.isEmpty {
            return [
                RitualRecommendation(id: "first-checkin", title: "Log the first check-in", detail: "Capture today’s energy, connection, and one honest note.", symbol: "square.and.pencil"),
                RitualRecommendation(id: "small-intention", title: "Set one tiny intention", detail: "Choose a next step simple enough to follow through tonight.", symbol: "target"),
                RitualRecommendation(id: "build-streak", title: "Build the baseline", detail: "Two or three entries are enough to make the dashboard more useful.", symbol: "flame")
            ]
        }

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
        if history.isEmpty {
            return "HeartSync is ready, but it needs a first check-in before the weekly story becomes meaningful."
        }

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
        guard !history.isEmpty else {
            return "Once you log a few check-ins, HeartSync will compare recent connection against the previous stretch."
        }

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

    var backupExportText: String {
        let payload = HeartSyncBackupExport(
            exportedAt: exportGeneratedAtLabel,
            partner: partner,
            history: history,
            draftEnergy: todayEnergy,
            draftConnection: todayConnection,
            draftNote: todayNote,
            draftIntention: todayIntention,
            schemaVersion: 1,
            containsSampleData: containsSampleData
        )

        guard let data = try? encoder.encode(payload),
              let text = String(data: data, encoding: .utf8) else {
            return "{ \"error\": \"Unable to encode HeartSync backup export.\" }"
        }

        return text
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
            ),
            DemoReadinessItem(
                id: "backup",
                title: "Backup export is current",
                detail: "Local demo data has a fresh JSON backup for handoff or recovery.",
                isReady: hasCurrentBackupExport || !hasHistory
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

    func launchReviewItems(appVersion: String, buildNumber: String, bundleIdentifier: String) -> [LaunchReviewItem] {
        [
            LaunchReviewItem(
                id: "release-id",
                title: "Release identity is visible",
                detail: "Version \(appVersion) (\(buildNumber)) and bundle ID \(bundleIdentifier) are ready for handoff.",
                isReady: !appVersion.isEmpty && !buildNumber.isEmpty && !bundleIdentifier.isEmpty
            ),
            LaunchReviewItem(
                id: "profile",
                title: "Scenario is presentation-ready",
                detail: "Partner profile, milestone, and support focus are set for the current story.",
                isReady: !partner.name.isEmpty && !partner.milestone.isEmpty && !partner.supportFocus.isEmpty
            ),
            LaunchReviewItem(
                id: "history",
                title: "Moments history is loaded",
                detail: "Home and Moments have enough data to show trends, recap, and recovery flows.",
                isReady: hasHistory
            ),
            LaunchReviewItem(
                id: "backup",
                title: "Backup safety is covered",
                detail: "A current backup exists or the app is intentionally in an empty-history state.",
                isReady: hasCurrentBackupExport || !hasHistory
            ),
            LaunchReviewItem(
                id: "summary",
                title: "Handoff text is ready",
                detail: "Weekly summary, release summary, and presenter copy actions are available from Profile.",
                isReady: !weeklySummaryText.isEmpty
            ),
        ]
    }

    func launchReviewSummary(appVersion: String, buildNumber: String, bundleIdentifier: String) -> String {
        let items = launchReviewItems(
            appVersion: appVersion,
            buildNumber: buildNumber,
            bundleIdentifier: bundleIdentifier
        )
        let readyCount = items.filter(\.isReady).count
        return "\(readyCount) of \(items.count) launch checks ready"
    }

    var currentScenarioSummary: String {
        let latestLabel = latestCheckInDate.map(dateContextLabel(for:)) ?? "No check-ins yet"
        return """
        Partner: \(partner.name)
        Milestone: \(partner.milestone)
        Support focus: \(partner.supportFocus)
        Moments loaded: \(history.count)
        Latest check-in: \(latestLabel)
        """
    }

    var currentScenarioText: String {
        """
        HeartSync current scenario
        Exported: \(exportGeneratedAtLabel)

        \(currentScenarioSummary)

        Weekly range: \(weeklyDateRangeLabel)
        Readiness: \(demoReadinessSummary)
        Relationship pulse: \(snapshot.relationshipPulse)/5
        Average energy: \(snapshot.weeklyAverageEnergy)/5
        Average connection: \(snapshot.weeklyAverageConnection)/5
        """
    }

    func releaseSummaryText(appVersion: String, buildNumber: String, bundleIdentifier: String) -> String {
        """
        HeartSync release summary
        Exported: \(exportGeneratedAtLabel)

        Version: \(appVersion) (\(buildNumber))
        Bundle ID: \(bundleIdentifier)
        Release track: Local-first single-user iOS app

        Included today:
        - Daily check-ins with local persistence
        - Dashboard pulse, trends, ritual plan, and weekly summary
        - Searchable, sortable, shareable moments history
        - Backup export plus pasted backup restore
        - Presenter/demo handoff tools
        - Store-level XCTest coverage

        Not included:
        - Accounts or cloud sync
        - Notifications
        - Analytics or CI/CD
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

    var defaultIntention: String {
        defaultIntentionText
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

    func copyCurrentScenarioToClipboard() {
        UIPasteboard.general.string = currentScenarioText
    }

    func copyBackupExportToClipboard() {
        UIPasteboard.general.string = backupExportText
        markBackupExported()
    }

    func copyReleaseSummaryToClipboard(appVersion: String, buildNumber: String, bundleIdentifier: String) {
        UIPasteboard.general.string = releaseSummaryText(
            appVersion: appVersion,
            buildNumber: buildNumber,
            bundleIdentifier: bundleIdentifier
        )
    }

    func backupPreviewSummary(for text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Paste a HeartSync backup JSON export here to preview what will be restored."
        }

        guard let payload = decodedBackupPayload(from: trimmed) else {
            return "The pasted text does not look like a valid HeartSync backup yet."
        }

        let latestLabel = payload.history.first.map { dateContextLabel(for: $0.date) } ?? "No saved moments"
        return """
        Backup preview
        Partner: \(payload.partner.name)
        Milestone: \(payload.partner.milestone)
        Moments: \(payload.history.count)
        Latest moment: \(latestLabel)
        Draft note: \(payload.draftNote.isEmpty ? "Empty" : "Included")
        """
    }

    func restoreFromBackupText(_ text: String) -> BackupRestoreResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return BackupRestoreResult(
                title: "Paste a backup first",
                detail: "Add the copied HeartSync backup JSON before trying to restore.",
                isSuccess: false
            )
        }

        guard let payload = decodedBackupPayload(from: trimmed) else {
            return BackupRestoreResult(
                title: "Backup could not be restored",
                detail: "The backup is unreadable, unsupported, or contains invalid ratings, duplicate days, or oversized text. Nothing was changed.",
                isSuccess: false
            )
        }

        preserveUnreadableState()
        recoveryMessage = nil
        apply(StoredHeartSyncState(partner: payload.partner, history: payload.history,
            draft: CheckInDraft(energy: payload.draftEnergy, connection: payload.draftConnection, note: payload.draftNote, intention: payload.draftIntention),
            containsSampleData: payload.containsSampleData ?? false))
        persistState()
        markBackupExported()

        return BackupRestoreResult(
            title: "Backup restored",
            detail: "Profile, moments, and draft state were restored from the pasted backup.",
            isSuccess: true
        )
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

    func restoreDefaultIntention() {
        todayIntention = defaultIntentionText
        saveDraft()
    }

    func saveDraft() {
        persistState()
    }

    @discardableResult
    func submitCheckIn() -> Bool {
        guard recoveryMessage == nil, HeartSyncValidation.draft(currentState.draft) else { return false }
        let today = Calendar.current.startOfDay(for: .now)
        let newCheckIn = DailyCheckIn(
            date: today,
            energy: Int(todayEnergy.rounded()),
            connection: Int(todayConnection.rounded()),
            note: todayNote.trimmingCharacters(in: .whitespacesAndNewlines),
            intention: todayIntention.trimmingCharacters(in: .whitespacesAndNewlines),
            partnerResponse: todayCheckIn?.partnerResponse
        )

        history.removeAll { Calendar.current.isDate($0.date, inSameDayAs: today) }
        history.insert(newCheckIn, at: 0)
        persistState()
        return true
    }

    /// Both people use the same device. A second response never replaces the first.
    @discardableResult
    func submitPartnerCheckIn(energy: Int, connection: Int, note: String, intention: String) -> Bool {
        guard recoveryMessage == nil, (1...5).contains(energy), (1...5).contains(connection),
              let index = history.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) else { return false }
        history[index].partnerResponse = PartnerCheckIn(
            energy: energy, connection: connection,
            note: String(note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2000)),
            intention: String(intention.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500))
        )
        persistHistory()
        return true
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
        guard recoveryMessage == nil else { return }
        apply(StoredHeartSyncState(partner: HeartSyncSampleData.partner, history: HeartSyncSampleData.history,
            draft: CheckInDraft(energy: 4, connection: 5, note: "", intention: defaultIntentionText), containsSampleData: true))
        persistState()
    }

    func clearAllHistory() {
        guard recoveryMessage == nil else { return }
        containsSampleData = false
        history = []
        persistHistory()
    }

    private func markDataUpdated() {
        defaults.set(Date.now, forKey: StorageKeys.dataUpdatedAt)
    }

    private func markBackupExported() {
        defaults.set(Date.now, forKey: StorageKeys.lastBackupExportAt)
    }

    private func decodedBackupPayload(from text: String) -> HeartSyncBackupExport? {
        guard text.utf8.count <= 5_000_000, let data = text.data(using: .utf8),
              let payload = try? decoder.decode(HeartSyncBackupExport.self, from: data),
              (payload.schemaVersion ?? 1) == 1,
              HeartSyncValidation.profile(payload.partner), HeartSyncValidation.history(payload.history),
              HeartSyncValidation.draft(CheckInDraft(energy: payload.draftEnergy, connection: payload.draftConnection, note: payload.draftNote, intention: payload.draftIntention)) else { return nil }
        return payload
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

    private func persistHistory() { persistState() }

    private func persistPartner() { persistState() }

    static var demoPresets: [DemoPreset] { HeartSyncSampleData.demoPresets }

    private func compareMomentsForStrength(lhs: DailyCheckIn, rhs: DailyCheckIn) -> Bool {
        if lhs.connection == rhs.connection {
            return lhs.energy < rhs.energy
        }

        return lhs.connection < rhs.connection
    }
}
