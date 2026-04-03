import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var store: HeartSyncStore
    @State private var selectedFilter: JournalFilter = .all

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Use these moments to spot patterns: when connection rises, what helped? When it drops, what was missing?")
                            .foregroundStyle(.secondary)

                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(JournalFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Weekly story")
                }

                Section("Recap") {
                    recapCard(
                        title: "Strongest connection",
                        value: bestConnectionEntry?.note ?? "No standout moment yet.",
                        symbol: "heart.fill",
                        tint: HeartSyncTheme.blush
                    )
                    recapCard(
                        title: "Needs extra care",
                        value: lowestConnectionEntry?.note ?? "No lower-connection moment yet.",
                        symbol: "bolt.horizontal.circle",
                        tint: HeartSyncTheme.coral
                    )
                }

                Section(selectedFilter.sectionTitle) {
                    ForEach(filteredHistory) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(item.date, format: .dateTime.weekday(.wide).month().day())
                                    .font(.headline)
                                Spacer()
                                Text("\(item.connection)/5 connected")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(connectionTint(for: item))
                            }

                            Text(item.note.isEmpty ? "No note was captured for this day." : item.note)
                                .font(.body)

                            Label("Intention: \(item.intention)", systemImage: "sparkles")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Label("Energy \(item.energy)/5", systemImage: "bolt.heart")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white.opacity(0.88))
                                .padding(.vertical, 4)
                        )
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HeartSyncTheme.background.ignoresSafeArea())
            .navigationTitle("Moments")
        }
    }

    private var filteredHistory: [DailyCheckIn] {
        switch selectedFilter {
        case .all:
            return store.history
        case .strong:
            return store.history.filter { $0.connection >= 4 }
        case .care:
            return store.history.filter { $0.connection <= 3 || $0.energy <= 3 }
        }
    }

    private var bestConnectionEntry: DailyCheckIn? {
        store.history.max { lhs, rhs in
            if lhs.connection == rhs.connection {
                return lhs.energy < rhs.energy
            }
            return lhs.connection < rhs.connection
        }
    }

    private var lowestConnectionEntry: DailyCheckIn? {
        store.history.min { lhs, rhs in
            if lhs.connection == rhs.connection {
                return lhs.energy < rhs.energy
            }
            return lhs.connection < rhs.connection
        }
    }

    private func connectionTint(for item: DailyCheckIn) -> Color {
        item.connection >= 4 ? HeartSyncTheme.sage : HeartSyncTheme.blush
    }

    private func recapCard(title: String, value: String, symbol: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(value)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private enum JournalFilter: String, CaseIterable, Identifiable {
    case all
    case strong
    case care

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .strong:
            return "Strong"
        case .care:
            return "Needs care"
        }
    }

    var sectionTitle: String {
        switch self {
        case .all:
            return "All moments"
        case .strong:
            return "Higher-connection days"
        case .care:
            return "Days needing extra care"
        }
    }
}

struct JournalView_Previews: PreviewProvider {
    static var previews: some View {
        JournalView()
            .environmentObject(HeartSyncStore())
    }
}
