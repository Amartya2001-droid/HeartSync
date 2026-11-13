import Foundation

struct CheckInDraft: Codable, Equatable {
    var energy: Double = 3
    var connection: Double = 3
    var note = ""
    var intention = ""
}

/// One encoded value prevents profile/history/draft writes from getting out of sync.
struct StoredHeartSyncState: Codable {
    var schemaVersion = 1
    var partner: PartnerProfile
    var history: [DailyCheckIn]
    var draft: CheckInDraft
    var containsSampleData: Bool

    var isValid: Bool {
        schemaVersion == 1 && HeartSyncValidation.profile(partner) &&
        HeartSyncValidation.history(history) && HeartSyncValidation.draft(draft)
    }
}

enum HeartSyncValidation {
    static func profile(_ profile: PartnerProfile) -> Bool {
        profile.name.count <= 200 && profile.milestone.count <= 500 && profile.supportFocus.count <= 2000
    }

    static func draft(_ draft: CheckInDraft) -> Bool {
        draft.energy.isFinite && draft.connection.isFinite &&
        (1...5).contains(draft.energy) && (1...5).contains(draft.connection) &&
        draft.note.count <= 2000 && draft.intention.count <= 500
    }

    static func history(_ entries: [DailyCheckIn]) -> Bool {
        guard entries.count <= 10000, Set(entries.map(\.id)).count == entries.count else { return false }
        // One response pair per local day is the app's data model.
        let calendar = Calendar.current
        guard Set(entries.map { calendar.startOfDay(for: $0.date) }).count == entries.count else { return false }
        return entries.allSatisfy { entry in
            guard entry.date.timeIntervalSince1970.isFinite,
                  (1...5).contains(entry.energy), (1...5).contains(entry.connection),
                  entry.note.count <= 2000, entry.intention.count <= 500 else { return false }
            guard let partner = entry.partnerResponse else { return true }
            return (1...5).contains(partner.energy) && (1...5).contains(partner.connection) &&
                partner.note.count <= 2000 && partner.intention.count <= 500
        }
    }
}
