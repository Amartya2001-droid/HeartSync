import Foundation

/// A response entered by the partner on this device, with their consent.
struct PartnerCheckIn: Codable, Equatable {
    var energy: Int
    var connection: Int
    var note: String
    var intention: String
}

struct CoupleDailySummary: Equatable {
    let connectionGap: Int
    let averageConnection: Double
    let conversationPrompt: String

    init?(entry: DailyCheckIn) {
        guard let partner = entry.partnerResponse else { return nil }
        connectionGap = abs(entry.connection - partner.connection)
        averageConnection = Double(entry.connection + partner.connection) / 2
        if min(entry.energy, partner.energy) <= 2 {
            conversationPrompt = "One of you is running low. Ask: what would make tonight feel a little easier?"
        } else if connectionGap >= 2 {
            conversationPrompt = "You felt connection differently today. Take turns asking: what helped you feel close, and what did you miss?"
        } else {
            conversationPrompt = "Name one moment you appreciated today, then choose one small intention together."
        }
    }
}
