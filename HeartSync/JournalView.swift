import Foundation
import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var store: HeartSyncStore
    @State private var selectedFilter: JournalFilter = .all
    @State private var searchText = ""

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

                        HStack {
                            Text(resultSummary)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(HeartSyncTheme.ink)
                            Spacer()
                            if !trimmedSearchText.isEmpty {
                                Button("Clear search") {
                                    searchText = ""
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(HeartSyncTheme.blush)
                            }
                        }
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

                Section("Week at a glance") {
                    HStack(spacing: 12) {
                        summaryPill(
                            title: "Entries",
                            value: "\(filteredHistory.count)",
                            tint: HeartSyncTheme.blush
                        )
                        summaryPill(
                            title: "Avg energy",
                            value: averageEnergyLabel,
                            tint: HeartSyncTheme.sage
                        )
                        summaryPill(
                            title: "Avg connection",
                            value: averageConnectionLabel,
                            tint: HeartSyncTheme.coral
                        )
                    }
                    .padding(.vertical, 6)
                }

                Section(selectedFilter.sectionTitle) {
                    if filteredHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(emptyStateTitle)
                                .font(.headline)
                            Text(emptyStateMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 10)
                        .listRowBackground(Color.white.opacity(0.72))
                    } else {
                        ForEach(filteredHistory) { item in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(store.dateContextLabel(for: item.date))
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
                        .onDelete { offsets in
                            store.deleteCheckIns(at: offsets, from: filteredHistory)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HeartSyncTheme.background.ignoresSafeArea())
            .navigationTitle("Moments")
            .searchable(text: $searchText, prompt: "Search notes or intentions")
        }
    }

    private var filteredHistory: [DailyCheckIn] {
        let entries: [DailyCheckIn]
        switch selectedFilter {
        case .all:
            entries = store.history
        case .strong:
            entries = store.history.filter { $0.connection >= 4 }
        case .care:
            entries = store.history.filter { $0.connection <= 3 || $0.energy <= 3 }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return entries }

        return entries.filter { entry in
            entry.note.localizedCaseInsensitiveContains(query) ||
            entry.intention.localizedCaseInsensitiveContains(query) ||
            store.dateContextLabel(for: entry.date).localizedCaseInsensitiveContains(query)
        }
    }

    private var resultSummary: String {
        let count = filteredHistory.count
        let label = count == 1 ? "moment" : "moments"
        if trimmedSearchText.isEmpty {
            return "\(count) \(label) in \(selectedFilter.title.lowercased())"
        }

        return "\(count) \(label) matching “\(trimmedSearchText)”"
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private var emptyStateTitle: String {
        if !trimmedSearchText.isEmpty {
            return "No matching moments"
        }

        switch selectedFilter {
        case .all:
            return "No moments yet"
        case .strong:
            return "No strong days captured yet"
        case .care:
            return "No lower-energy or lower-connection days right now"
        }
    }

    private var emptyStateMessage: String {
        if !trimmedSearchText.isEmpty {
            return "Try a different word from a note, intention, or date label."
        }

        switch selectedFilter {
        case .all:
            return "Complete a check-in and it will show up here as part of your shared story."
        case .strong:
            return "Once a higher-connection day is logged, this filter will make those bright spots easy to revisit."
        case .care:
            return "This filter is for moments that may need a little more repair, honesty, or support."
        }
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

    private var averageEnergyLabel: String {
        averageLabel(for: filteredHistory.map(\.energy))
    }

    private var averageConnectionLabel: String {
        averageLabel(for: filteredHistory.map(\.connection))
    }

    private func averageLabel(for values: [Int]) -> String {
        guard !values.isEmpty else { return "--" }
        let average = Double(values.reduce(0, +)) / Double(values.count)
        return String(format: "%.1f/5", average)
    }

    private func summaryPill(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
