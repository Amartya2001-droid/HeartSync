import XCTest
@testable import HeartSync

@MainActor
final class HeartSyncStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "HeartSyncStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        if let suiteName {
            defaults.removePersistentDomain(forName: suiteName)
        }
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testSubmitCheckInPersistsTrimmedEntryAndResetsDraft() {
        let store = HeartSyncStore(defaults: defaults)

        store.todayEnergy = 2
        store.todayConnection = 4
        store.todayNote = "  Needed a calmer conversation tonight.  "
        store.todayIntention = "  Protect 15 minutes after dinner.  "

        store.submitCheckIn()

        guard let todayCheckIn = store.todayCheckIn else {
            return XCTFail("Expected a saved check-in for today.")
        }

        XCTAssertEqual(todayCheckIn.energy, 2)
        XCTAssertEqual(todayCheckIn.connection, 4)
        XCTAssertEqual(todayCheckIn.note, "Needed a calmer conversation tonight.")
        XCTAssertEqual(todayCheckIn.intention, "Protect 15 minutes after dinner.")
        XCTAssertEqual(store.todayNote, "")
        XCTAssertEqual(store.todayIntention, store.defaultIntention)

        let reloadedStore = HeartSyncStore(defaults: defaults)
        XCTAssertEqual(reloadedStore.todayCheckIn?.note, "Needed a calmer conversation tonight.")
        XCTAssertEqual(reloadedStore.todayCheckIn?.intention, "Protect 15 minutes after dinner.")
    }

    func testSnapshotStreakCountsOnlyConsecutiveDaysIncludingToday() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let history = [
            DailyCheckIn(date: today, energy: 4, connection: 4, note: "Today", intention: "Keep it steady"),
            DailyCheckIn(date: try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today)), energy: 3, connection: 4, note: "Yesterday", intention: "Check in earlier"),
            DailyCheckIn(date: try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: today)), energy: 5, connection: 5, note: "Two days ago", intention: "Protect dinner"),
            DailyCheckIn(date: try XCTUnwrap(calendar.date(byAdding: .day, value: -4, to: today)), energy: 2, connection: 3, note: "Gap day", intention: "Try again tomorrow"),
        ]

        let data = try JSONEncoder.iso8601.encode(history)
        defaults.set(data, forKey: "heartsync.history")

        let reloadedStore = HeartSyncStore(defaults: defaults)
        XCTAssertEqual(reloadedStore.snapshot.streakDays, 3)
    }

    func testBackupExportFreshnessChangesAfterExportAndLaterEdit() {
        let store = HeartSyncStore(defaults: defaults)

        XCTAssertFalse(store.hasCurrentBackupExport)
        XCTAssertEqual(store.exportStatus.title, "Backup export recommended")

        store.copyBackupExportToClipboard()

        XCTAssertTrue(store.hasCurrentBackupExport)
        XCTAssertEqual(store.exportStatus.title, "Backup export is current")

        store.todayNote = "A new local draft change"
        store.saveDraft()

        XCTAssertFalse(store.hasCurrentBackupExport)
        XCTAssertEqual(store.exportStatus.title, "Backup export needs refresh")
    }

    func testRestoreFromBackupTextReplacesProfileHistoryAndDraft() {
        let sourceStore = HeartSyncStore(defaults: defaults)
        sourceStore.updatePartner(name: "Taylor", milestone: "Rebuild week", supportFocus: "More honest repair conversations")
        sourceStore.todayEnergy = 5
        sourceStore.todayConnection = 2
        sourceStore.todayNote = "Draft note to restore"
        sourceStore.todayIntention = "Draft intention to restore"
        sourceStore.submitCheckIn()

        let backupText = sourceStore.backupExportText

        let restoreSuiteName = "HeartSyncStoreRestoreTests-\(UUID().uuidString)"
        let otherDefaults = UserDefaults(suiteName: restoreSuiteName)!
        otherDefaults.removePersistentDomain(forName: restoreSuiteName)
        let restoredStore = HeartSyncStore(defaults: otherDefaults)

        let result = restoredStore.restoreFromBackupText(backupText)

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.title, "Backup restored")
        XCTAssertEqual(restoredStore.partner.name, "Taylor")
        XCTAssertEqual(restoredStore.partner.milestone, "Rebuild week")
        XCTAssertEqual(restoredStore.partner.supportFocus, "More honest repair conversations")
        XCTAssertEqual(restoredStore.todayEnergy, sourceStore.todayEnergy)
        XCTAssertEqual(restoredStore.todayConnection, sourceStore.todayConnection)
        XCTAssertEqual(restoredStore.history.count, sourceStore.history.count)
        XCTAssertEqual(restoredStore.todayCheckIn?.note, sourceStore.todayCheckIn?.note)
        XCTAssertTrue(restoredStore.hasCurrentBackupExport)

        otherDefaults.removePersistentDomain(forName: restoreSuiteName)
    }

    func testRestoreFromInvalidBackupTextFailsWithoutChangingState() {
        let store = HeartSyncStore(defaults: defaults)
        let originalPartnerName = store.partner.name
        let originalHistoryCount = store.history.count

        let result = store.restoreFromBackupText("not valid backup json")

        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(result.title, "Backup could not be restored")
        XCTAssertEqual(store.partner.name, originalPartnerName)
        XCTAssertEqual(store.history.count, originalHistoryCount)
    }

    func testClearAllHistoryMakesBackupOptionalAndHistoryEmpty() {
        let store = HeartSyncStore(defaults: defaults)

        XCTAssertTrue(store.hasHistory)

        store.clearAllHistory()

        XCTAssertFalse(store.hasHistory)
        XCTAssertEqual(store.exportStatus.title, "Backup export is optional right now")

        let reloadedStore = HeartSyncStore(defaults: defaults)
        XCTAssertFalse(reloadedStore.hasHistory)
        XCTAssertEqual(reloadedStore.history.count, 0)
    }
}

private extension JSONEncoder {
    static var iso8601: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
