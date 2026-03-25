import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: HeartSyncStore

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "heart.text.square")
                }

            CheckInView()
                .tabItem {
                    Label("Check-In", systemImage: "slider.horizontal.3")
                }

            JournalView()
                .tabItem {
                    Label("Moments", systemImage: "book.closed")
                }

            SettingsView()
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(HeartSyncStore())
    }
}
