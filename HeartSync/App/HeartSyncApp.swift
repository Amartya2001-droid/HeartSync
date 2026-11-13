import SwiftUI

@main
struct HeartSyncApp: App {
    @StateObject private var store: HeartSyncStore
    private let defaults: UserDefaults

    init() {
        var storage = UserDefaults.standard
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--ui-testing") {
            let suite = "HeartSync.UITests"
            storage = UserDefaults(suiteName: suite)!
            if arguments.contains("--reset") { storage.removePersistentDomain(forName: suite) }
            if arguments.contains("--skip-onboarding") {
                storage.set(false, forKey: "heartsync.shouldShowOnboarding")
                storage.set(true, forKey: "heartsync.hasAcknowledgedEmptyHistory")
            }
        }
        #endif
        defaults = storage
        let initialStore = HeartSyncStore(defaults: storage)
        #if DEBUG
        if arguments.contains("--ui-testing"), arguments.contains("--samples") { initialStore.resetDemoData() }
        #endif
        _store = StateObject(wrappedValue: initialStore)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .defaultAppStorage(defaults)
        }
    }
}
