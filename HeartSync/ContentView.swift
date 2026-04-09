import SwiftUI

enum HeartSyncTab: Hashable {
    case home
    case checkIn
    case moments
    case profile
}

struct ContentView: View {
    @EnvironmentObject private var store: HeartSyncStore
    @AppStorage("heartsync.shouldShowOnboarding") private var shouldShowOnboarding = true
    @State private var selectedTab: HeartSyncTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tag(HeartSyncTab.home)
                .tabItem {
                    Label("Home", systemImage: "heart.text.square")
                }

            CheckInView()
                .tag(HeartSyncTab.checkIn)
                .tabItem {
                    Label("Check-In", systemImage: "slider.horizontal.3")
                }

            JournalView()
                .tag(HeartSyncTab.moments)
                .tabItem {
                    Label("Moments", systemImage: "book.closed")
                }

            SettingsView()
                .tag(HeartSyncTab.profile)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(HeartSyncTheme.blush)
        .preferredColorScheme(.light)
        .onChange(of: store.todayEnergy) { _, _ in store.saveDraft() }
        .onChange(of: store.todayConnection) { _, _ in store.saveDraft() }
        .onChange(of: store.todayNote) { _, _ in store.saveDraft() }
        .onChange(of: store.todayIntention) { _, _ in store.saveDraft() }
        .sheet(isPresented: $shouldShowOnboarding) {
            OnboardingSheetView(isPresented: $shouldShowOnboarding)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct OnboardingStep: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
}

private struct OnboardingSheetView: View {
    @Binding var isPresented: Bool

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            id: "pulse",
            title: "Track your relationship pulse",
            detail: "See connection, energy, streaks, and recent reflections in one calm dashboard.",
            symbol: "heart.text.square.fill"
        ),
        OnboardingStep(
            id: "checkin",
            title: "Capture one honest check-in a day",
            detail: "Log energy, connection, a short note, and a single intention in under a minute.",
            symbol: "slider.horizontal.3"
        ),
        OnboardingStep(
            id: "demo",
            title: "Make demos easy",
            detail: "Use presets and reset controls from Profile whenever you want a fresh presentation state.",
            symbol: "sparkles.rectangle.stack.fill"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Welcome to HeartSync")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(HeartSyncTheme.ink)
                        Text("A lightweight relationship check-in app built for daily reflection and fast demos.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(steps) { step in
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: step.symbol)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(HeartSyncTheme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(step.title)
                                    .font(.headline)
                                    .foregroundStyle(HeartSyncTheme.ink)
                                Text(step.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
                        )
                    }

                    Button {
                        isPresented = false
                    } label: {
                        Text("Start checking in")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(HeartSyncTheme.accent, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(HeartSyncTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        isPresented = false
                    }
                    .foregroundStyle(HeartSyncTheme.blush)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(HeartSyncStore())
    }
}
