import Foundation

/// Calendar-based presentation state shared by Home and its regression tests.
struct HomeOverview {
    enum Phase: Equatable {
        case recovery, notStarted, waitingForPartner, together

        var title: String {
            switch self {
            case .recovery: return "Let’s recover your story."
            case .notStarted: return "Make a little room for each other."
            case .waitingForPartner: return "One perspective saved. One to go."
            case .together: return "You both showed up today."
            }
        }

        var actionTitle: String {
            switch self {
            case .recovery: return "Recover saved data"
            case .notStarted: return "Start today’s check-in"
            case .waitingForPartner: return "Add partner’s check-in"
            case .together: return "View your shared check-in"
            }
        }
    }

    struct Day: Identifiable {
        let date: Date
        let entry: DailyCheckIn?
        var id: Date { date }
    }

    let phase: Phase
    let today: DailyCheckIn?
    let days: [Day]
    let averageConnection: Double?
    let daysCheckedIn: Int
    let daysTogether: Int

    init(history: [DailyCheckIn], needsRecovery: Bool, now: Date = .now, calendar: Calendar = .current) {
        let start = calendar.startOfDay(for: now)
        days = (-6...0).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let entry = history.filter { calendar.isDate($0.date, inSameDayAs: date) }.max { $0.date < $1.date }
            return Day(date: date, entry: entry)
        }
        today = days.last?.entry
        if needsRecovery { phase = .recovery }
        else if today == nil { phase = .notStarted }
        else if today?.partnerResponse == nil { phase = .waitingForPartner }
        else { phase = .together }
        let entries = days.compactMap(\.entry)
        daysCheckedIn = entries.count
        daysTogether = entries.filter { $0.partnerResponse != nil }.count
        averageConnection = entries.isEmpty ? nil : Double(entries.reduce(0) { $0 + $1.connection }) / Double(entries.count)
    }
}
