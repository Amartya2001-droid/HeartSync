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
    @AppStorage("heartsync.hasAcknowledgedEmptyHistory") private var hasAcknowledgedEmptyHistory = false
    @State private var selectedTab: HeartSyncTab = .home
    @State private var activeSheetMode: OnboardingSheetMode?

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
        .onAppear {
            updateSheetPresentation()
        }
        .onChange(of: shouldShowOnboarding) { _, _ in
            updateSheetPresentation()
        }
        .onChange(of: store.hasHistory) { _, hasHistory in
            if hasHistory {
                hasAcknowledgedEmptyHistory = false
            } else if !shouldShowOnboarding {
                hasAcknowledgedEmptyHistory = false
            }

            updateSheetPresentation()
        }
        .sheet(item: $activeSheetMode) { mode in
            OnboardingSheetView(
                mode: mode,
                selectedTab: $selectedTab,
                dismissSheet: dismissSheet(for:)
            )
            .environmentObject(store)
            .interactiveDismissDisabled(mode == .emptyHistory)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func updateSheetPresentation() {
        if shouldShowOnboarding {
            activeSheetMode = .welcome
        } else if !store.hasHistory && !hasAcknowledgedEmptyHistory {
            activeSheetMode = .emptyHistory
        } else if activeSheetMode != nil {
            activeSheetMode = nil
        }
    }

    private func dismissSheet(for mode: OnboardingSheetMode) {
        switch mode {
        case .welcome:
            shouldShowOnboarding = false
        case .emptyHistory:
            hasAcknowledgedEmptyHistory = true
            activeSheetMode = nil
        }
    }
}

private enum OnboardingSheetMode: String, Identifiable {
    case welcome
    case emptyHistory

    var id: String { rawValue }
}

private struct OnboardingStep: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
}

private struct OnboardingHeader {
    let title: String
    let detail: String
    let actionTitle: String
    let skipTitle: String
}

private struct RecoveryAction: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let action: () -> Void
}

private struct OnboardingSheetView: View {
    @EnvironmentObject private var store: HeartSyncStore
    let mode: OnboardingSheetMode
    @Binding var selectedTab: HeartSyncTab
    let dismissSheet: (OnboardingSheetMode) -> Void

    private var header: OnboardingHeader {
        switch mode {
        case .welcome:
            return OnboardingHeader(
                title: "Welcome to HeartSync",
                detail: "A lightweight relationship check-in app built for daily reflection and fast demos.",
                actionTitle: "Start checking in",
                skipTitle: "Skip"
            )
        case .emptyHistory:
            return OnboardingHeader(
                title: "Moments history was cleared",
                detail: "HeartSync is still ready, but the dashboard needs fresh check-ins or restored sample data before it can tell a useful story again.",
                actionTitle: "Start first check-in",
                skipTitle: "Not now"
            )
        }
    }

    private var recoveryActions: [RecoveryAction] {
        [
            RecoveryAction(
                id: "checkin",
                title: "Start a new first check-in",
                detail: "Log today's energy, connection, note, and intention so Home and Moments become useful again.",
                symbol: "square.and.pencil",
                action: {
                    selectedTab = .checkIn
                    dismissSheet(.emptyHistory)
                }
            ),
            RecoveryAction(
                id: "sample",
                title: "Restore sample data",
                detail: "Bring back the default demo profile and moments if you need a presentation-ready state quickly.",
                symbol: "arrow.counterclockwise.circle.fill",
                action: {
                    store.resetDemoData()
                    selectedTab = .home
                    dismissSheet(.emptyHistory)
                }
            ),
        ]
    }

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            id: "pulse",
            title: "Track your relationship pulse",
            detail: "See connection, energy, streaks, trends, and a ritual plan in one calm dashboard.",
            symbol: "heart.text.square.fill"
        ),
        OnboardingStep(
            id: "checkin",
            title: "Capture one honest check-in a day",
            detail: "Log energy, connection, a short note, and a single intention with coaching hints in under a minute.",
            symbol: "slider.horizontal.3"
        ),
        OnboardingStep(
            id: "moments",
            title: "Revisit and share moments",
            detail: "Search, sort, and share individual reflections from the Moments timeline.",
            symbol: "book.closed.fill"
        ),
        OnboardingStep(
            id: "demo",
            title: "Make demos easy",
            detail: "Use presets, demo readiness, and presenter handoff tools from Profile whenever you want a fresh presentation state.",
            symbol: "sparkles.rectangle.stack.fill"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(header.title)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(HeartSyncTheme.ink)
                        Text(header.detail)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    switch mode {
                    case .welcome:
                        onboardingSteps
                    case .emptyHistory:
                        recoveryCards
                    }

                    Button {
                        primaryAction()
                    } label: {
                        Text(header.actionTitle)
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
                    Button(header.skipTitle) {
                        dismissSheet(mode)
                    }
                    .foregroundStyle(HeartSyncTheme.blush)
                }
            }
        }
    }

    @ViewBuilder
    private var onboardingSteps: some View {
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
    }

    private var recoveryCards: some View {
        VStack(spacing: 14) {
            ForEach(recoveryActions) { item in
                Button {
                    item.action()
                } label: {
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(HeartSyncTheme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(HeartSyncTheme.ink)
                            Text(item.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func primaryAction() {
        switch mode {
        case .welcome:
            dismissSheet(.welcome)
        case .emptyHistory:
            selectedTab = .checkIn
            dismissSheet(.emptyHistory)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(HeartSyncStore())
    }
}
