import SwiftUI

/// Every preview gets a fresh suite: edits and onboarding flags cannot touch app storage.
@MainActor
struct HeartSyncPreview<Content: View>: View {
    @StateObject private var context: HeartSyncPreviewContext
    private let content: () -> Content

    init(emptyHistory: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        _context = StateObject(wrappedValue: HeartSyncPreviewContext(emptyHistory: emptyHistory))
        self.content = content
    }

    var body: some View {
        content()
            .environmentObject(context.store)
            .defaultAppStorage(context.defaults)
    }
}

/// Keep the store and AppStorage suite together across SwiftUI view updates.
@MainActor
private final class HeartSyncPreviewContext: ObservableObject {
    let defaults: UserDefaults
    let store: HeartSyncStore

    init(emptyHistory: Bool) {
        let defaults = HeartSyncStore.makePreviewDefaults()
        self.defaults = defaults
        store = HeartSyncStore.makePreview(defaults: defaults, emptyHistory: emptyHistory)
    }
}

extension HeartSyncStore {
    static func makePreviewDefaults() -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: "HeartSync.Preview.\(UUID().uuidString)") else {
            preconditionFailure("Could not create isolated preview storage")
        }
        defaults.set(false, forKey: "heartsync.shouldShowOnboarding")
        defaults.set(true, forKey: "heartsync.hasAcknowledgedEmptyHistory")
        return defaults
    }

    static func makePreview(defaults: UserDefaults? = nil, emptyHistory: Bool = false) -> HeartSyncStore {
        let store = HeartSyncStore(defaults: defaults ?? makePreviewDefaults())
        if emptyHistory { store.clearAllHistory() } else { store.resetDemoData() }
        return store
    }
}
