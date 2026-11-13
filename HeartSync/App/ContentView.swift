import SwiftUI

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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HeartSyncPreview { ContentView() }
                .previewDisplayName("Sample history")
            HeartSyncPreview(emptyHistory: true) { ContentView() }
                .previewDisplayName("Empty history")
        }
    }
}
