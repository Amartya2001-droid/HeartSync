import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: HeartSyncStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var selectedTab: HeartSyncTab
    @State private var showSharedCheckIn = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let overview = HomeOverview(history: store.history, needsRecovery: store.recoveryMessage != nil, now: context.date)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            header(date: context.date)
                            if store.containsSampleData {
                                Label("Fictional sample history — clear it in Profile to start your own story.", systemImage: "sparkles")
                                    .font(.callout)
                                    .padding(14)
                                    .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
                            }
                            dailyCard(overview)
                            if let entry = overview.today, let summary = CoupleDailySummary(entry: entry), overview.phase != .recovery {
                                conversationCard(summary)
                            }
                            if overview.phase != .recovery {
                                weekCard(overview)
                                recentReflections
                            }
                            Label("Same device. No accounts. No partner sync.", systemImage: "iphone")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: max(0, geometry.size.width - 40), alignment: .leading)
                        .padding(20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(HeartSyncTheme.background.ignoresSafeArea())
            .navigationTitle("HeartSync")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSharedCheckIn) { CoupleCheckInView() }
        }
    }

    private func header(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("A small pause.\nA closer connection.")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(HeartSyncTheme.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Name how you feel, listen to each other, and choose one small intention together.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func dailyCard(_ overview: HomeOverview) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("TODAY, TOGETHER", systemImage: "heart.text.square.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(HeartSyncTheme.blush)
            Text(overview.phase.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("home.phaseTitle")
            if let message = store.recoveryMessage {
                Text(message).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    progressRow("Your reflection", complete: overview.today != nil)
                    progressRow("\(store.partner.name)’s perspective", complete: overview.today?.partnerResponse != nil)
                    progressRow("A conversation to take with you", complete: overview.phase == .together)
                }
                if overview.phase == .notStarted {
                    Text("Start with your own feelings. Your partner can add theirs when they’re ready.")
                        .foregroundStyle(.secondary)
                } else if overview.phase == .waitingForPartner {
                    Text("Pass the device when your partner is ready. They choose what to share; both responses are visible in this app.")
                        .foregroundStyle(.secondary)
                }
            }
            Button {
                switch overview.phase {
                case .recovery: selectedTab = .profile
                case .notStarted: selectedTab = .checkIn
                case .waitingForPartner, .together: showSharedCheckIn = true
                }
            } label: {
                HStack {
                    Text(overview.phase.actionTitle)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    if !dynamicTypeSize.isAccessibilitySize { Image(systemName: "arrow.right") }
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(.white)
                .background(HeartSyncTheme.ink, in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.primaryAction")
            if overview.today != nil, overview.phase != .recovery {
                Button("Edit your reflection") {
                    store.loadTodayCheckInIntoDraft()
                    selectedTab = .checkIn
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(HeartSyncTheme.ink)
                .padding(.vertical, 8)
                .accessibilityIdentifier("home.editReflection")
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(HeartSyncTheme.cardBorder))
    }

    private func progressRow(_ title: String, complete: Bool) -> some View {
        Label(title, systemImage: complete ? "checkmark.circle.fill" : "circle")
            .font(.subheadline)
            .foregroundStyle(complete ? HeartSyncTheme.ink : HeartSyncTheme.ink.opacity(0.6))
            .accessibilityLabel("\(title), \(complete ? "complete" : "not yet")")
    }

    private func conversationCard(_ summary: CoupleDailySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Take this into your evening", systemImage: "bubble.left.and.bubble.right")
                .font(.headline)
            Text(summary.conversationPrompt)
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)
            Text("A reflection prompt, not a relationship score.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HeartSyncTheme.sage.opacity(0.15), in: RoundedRectangle(cornerRadius: 24))
    }

    private func weekCard(_ overview: HomeOverview) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your last seven days").font(.title3.bold()).accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 12) {
                ForEach(overview.days) { day in
                    VStack(spacing: 10) {
                        Text(day.date.formatted(.dateTime.weekday(.narrow))).font(.caption2)
                        Image(systemName: day.entry?.partnerResponse != nil ? "person.2.circle.fill" : day.entry != nil ? "checkmark.circle.fill" : "circle.dotted")
                            .font(.system(size: 22))
                            .foregroundStyle(day.entry == nil ? HeartSyncTheme.ink.opacity(0.35) : HeartSyncTheme.blush)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.date.formatted(date: .complete, time: .omitted)), \(day.entry?.partnerResponse != nil ? "both checked in" : day.entry != nil ? "you checked in" : "no check-in")")
                }
            }
            Divider()
            if let average = overview.averageConnection {
                Text("\(overview.daysCheckedIn) of 7 days checked in · \(overview.daysTogether) together")
                    .font(.subheadline.weight(.semibold))
                Text("Your average connection: \(average.formatted(.number.precision(.fractionLength(1))))/5, from your recorded days only.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                Text("No check-ins in the last seven days. Your first reflection will begin the picture — no score is assumed.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 24))
    }

    private var recentReflections: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your story so far").font(.title3.bold()).accessibilityAddTraits(.isHeader)
            Button("All moments") { selectedTab = .moments }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(HeartSyncTheme.ink)
                .accessibilityIdentifier("home.allMoments")
            if let latest = store.history.first {
                Text(latest.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary)
                Text(latest.note.isEmpty ? "You made space to name how you felt." : latest.note)
                    .lineLimit(4)
                if !latest.intention.isEmpty { Label(latest.intention, systemImage: "sparkles").font(.subheadline) }
            } else {
                Text("The ordinary moments count. Save one today, then revisit it here whenever you need a reminder.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 24))
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HeartSyncPreview(emptyHistory: true) { DashboardView(selectedTab: .constant(.home)) }
                .previewDisplayName("Start your story")
            HeartSyncPreview { DashboardView(selectedTab: .constant(.home)) }
                .previewDisplayName("Waiting for partner")
        }
    }
}
