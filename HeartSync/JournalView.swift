import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var store: HeartSyncStore

    var body: some View {
        NavigationStack {
            List {
                Section("Weekly story") {
                    Text("Use these moments to spot patterns: when connection rises, what helped? When it drops, what was missing?")
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }

                ForEach(store.history) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(item.date, format: .dateTime.weekday(.wide).month().day())
                                .font(.headline)
                            Spacer()
                            Text("\(item.connection)/5 connected")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HeartSyncTheme.blush)
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
            .scrollContentBackground(.hidden)
            .background(HeartSyncTheme.background.ignoresSafeArea())
            .navigationTitle("Moments")
        }
    }
}

struct JournalView_Previews: PreviewProvider {
    static var previews: some View {
        JournalView()
            .environmentObject(HeartSyncStore())
    }
}
