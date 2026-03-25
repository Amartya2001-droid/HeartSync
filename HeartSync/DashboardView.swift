import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: HeartSyncStore

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

                    focusCard
                    insightCard
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

    private var recentMoments: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent moments")
                .font(.title3.weight(.semibold))
                .foregroundStyle(HeartSyncTheme.ink)

            ForEach(store.recentMoments) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.date, format: .dateTime.weekday(.abbreviated).month().day())
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
        return latest.formatted(.dateTime.month(.abbreviated).day())
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
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(HeartSyncStore())
    }
}
