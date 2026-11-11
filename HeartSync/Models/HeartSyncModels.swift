import Foundation

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

struct LaunchReviewItem: Identifiable, Hashable {
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

struct ExportStatusSnapshot {
    let title: String
    let detail: String
    let isCurrent: Bool
}

struct BackupRestoreResult {
    let title: String
    let detail: String
    let isSuccess: Bool
}

struct HeartSyncBackupExport: Codable {
    let exportedAt: String
    let partner: PartnerProfile
    let history: [DailyCheckIn]
    let draftEnergy: Double
    let draftConnection: Double
    let draftNote: String
    let draftIntention: String
}
