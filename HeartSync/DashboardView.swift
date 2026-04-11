import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: HeartSyncStore
    @Binding var selectedTab: HeartSyncTab

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MetricCard(
                            title: "Pulse",
                            value: "\(store.snapshot.relationshipPulse)/5",
                            detail: "Average connection this week",
                            symbol: "heart.fill",
                            tint: HeartSyncTheme.blush
                        )
                        MetricCard(
                            title: "Streak",
                            value: "\(store.snapshot.streakDays) days",
                            detail: "Consecutive daily check-ins",
                            symbol: "flame.fill",
                            tint: HeartSyncTheme.coral
                        )
                        MetricCard(
                            title: "Energy",
                            value: "\(store.snapshot.weeklyAverageEnergy)/5",
                            detail: "Average emotional energy",
                            symbol: "bolt.heart.fill",
                            tint: HeartSyncTheme.sage
                        )
                        MetricCard(
                            title: "Latest",
                            value: latestDateLabel,
                            detail: "Most recent reflection",
                            symbol: "calendar",
                            tint: HeartSyncTheme.ink
                        )
                    }

                    trendCard
                    focusCard
                    quickActionsCard
                    todayStatusCard
                    insightCard
                    summaryCard
                    recentMoments
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .background(HeartSyncTheme.background.ignoresSafeArea())
            .navigationTitle("HeartSync")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("A calmer way to stay emotionally in sync.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(HeartSyncTheme.ink)

            Text("Track how the relationship feels, capture small moments that mattered, and set one intention for today.")
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label(store.partner.name, systemImage: "person.2.fill")
                Label(store.partner.milestone, systemImage: "sparkles")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(HeartSyncTheme.ink.opacity(0.85))

            HStack(spacing: 14) {
                statPill(title: "Connection", value: "\(store.snapshot.weeklyAverageConnection)/5")
                statPill(title: "Support Focus", value: store.partner.supportFocus)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(HeartSyncTheme.accent)
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 180, height: 180)
                    .offset(x: 48, y: -72)
            }
        }
        .foregroundStyle(.white)
    }

    private var focusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s focus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(HeartSyncTheme.ink)

            Text(store.todayIntention.isEmpty ? "Name one small way you want to show up for each other today." : store.todayIntention)
                .font(.body)
                .foregroundStyle(.secondary)

            NavigationLink {
                CheckInView()
            } label: {
                Text("Update today’s check-in")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(HeartSyncTheme.ink, in: Capsule())
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
        )
    }

    private var trendCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2.weight(.semibold))
                .foregroundStyle(HeartSyncTheme.sage)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(store.connectionTrendTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(HeartSyncTheme.ink)
                Text(store.connectionTrendMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
        )
    }

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What this week is saying")
                .font(.title3.weight(.semibold))
                .foregroundStyle(HeartSyncTheme.ink)

            Text(store.weeklyStory)
                .font(.body)
                .foregroundStyle(.secondary)

            Divider()

            Label(store.recommendedAction, systemImage: "bolt.badge.clock")
                .font(.subheadline)
                .foregroundStyle(HeartSyncTheme.ink)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
        )
    }

    private var todayStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(store.todayStatusTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(HeartSyncTheme.ink)
                Spacer()
                Label(
                    store.hasCompletedTodayCheckIn ? "Done" : "Pending",
                    systemImage: store.hasCompletedTodayCheckIn ? "checkmark.circle.fill" : "clock.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(store.hasCompletedTodayCheckIn ? HeartSyncTheme.sage : HeartSyncTheme.coral)
            }

            Text(store.todayStatusMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(4)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
        )
    }

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Jump back in")
                .font(.title3.weight(.semibold))
                .foregroundStyle(HeartSyncTheme.ink)

            Text("Use Home as the launch point for your next check-in, recap, or profile tweak.")
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                quickActionButton(
                    title: "Check-In",
                    symbol: "slider.horizontal.3",
                    tint: HeartSyncTheme.coral
                ) {
                    selectedTab = .checkIn
                }

                quickActionButton(
                    title: "Moments",
                    symbol: "book.closed",
                    tint: HeartSyncTheme.sage
                ) {
                    selectedTab = .moments
                }

                quickActionButton(
                    title: "Profile",
                    symbol: "person.crop.circle",
                    tint: HeartSyncTheme.blush
                ) {
                    selectedTab = .profile
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
        )
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Take this week with you")
                .font(.title3.weight(.semibold))
                .foregroundStyle(HeartSyncTheme.ink)

            Text(store.weeklyStory)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            VStack(alignment: .leading, spacing: 10) {
                summaryHighlight(
                    title: "What helped",
                    detail: store.strongestMomentSummary,
                    tint: HeartSyncTheme.sage
                )
                summaryHighlight(
                    title: "Needs care",
                    detail: store.needsCareSummary,
                    tint: HeartSyncTheme.coral
                )
            }

            ShareLink(
                item: store.weeklySummaryText,
                subject: Text(store.weeklySummaryTitle),
                message: Text("Shared from HeartSync")
            ) {
                Label("Share weekly summary", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(HeartSyncTheme.ink, in: Capsule())
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
        )
    }

    private var recentMoments: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent moments")
                .font(.title3.weight(.semibold))
                .foregroundStyle(HeartSyncTheme.ink)

            ForEach(store.recentMoments) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.dateContextLabel(for: item.date))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HeartSyncTheme.blush)
                    Text(item.note.isEmpty ? "No note captured for this day." : item.note)
                        .font(.body)
                        .foregroundStyle(HeartSyncTheme.ink)
                    Text("Intention: \(item.intention)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }

    private var latestDateLabel: String {
        guard let latest = store.latestCheckInDate else { return "None" }
        return store.dateContextLabel(for: latest)
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .opacity(0.78)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func quickActionButton(title: String, symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol)
                    .font(.headline)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
            .padding(.horizontal, 14)
            .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func summaryHighlight(title: String, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
            Text(detail)
                .font(.caption)
                .foregroundStyle(HeartSyncTheme.ink)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(selectedTab: .constant(.home))
            .environmentObject(HeartSyncStore())
    }
}
