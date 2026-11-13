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
        HeartSyncStore(defaults: defaults).resetDemoData()
    }

    override func tearDown() {
        if let suiteName {
            defaults.removePersistentDomain(forName: suiteName)
        }
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testHomeOverviewChoosesTheNextActionFromBothPerspectives() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        var entry = DailyCheckIn(date: now, energy: 3, connection: 4, note: "", intention: "")
        XCTAssertEqual(HomeOverview(history: [], needsRecovery: false, now: now, calendar: calendar).phase, .notStarted)
        XCTAssertEqual(HomeOverview(history: [entry], needsRecovery: false, now: now, calendar: calendar).phase, .waitingForPartner)
        entry.partnerResponse = PartnerCheckIn(energy: 3, connection: 3, note: "", intention: "")
        let shared = HomeOverview(history: [entry], needsRecovery: false, now: now, calendar: calendar)
        XCTAssertEqual(shared.phase, .together)
        XCTAssertEqual(shared.daysTogether, 1)
        XCTAssertEqual(HomeOverview(history: [entry], needsRecovery: true, now: now, calendar: calendar).phase, .recovery)
    }

    func testHomeWeekExcludesOldAndFutureEntriesAndNeverAssumesAnEmptyScore() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let today = calendar.startOfDay(for: now)
        func entry(_ offset: Int, _ connection: Int) throws -> DailyCheckIn {
            DailyCheckIn(date: try XCTUnwrap(calendar.date(byAdding: .day, value: offset, to: today)), energy: 3, connection: connection, note: "", intention: "")
        }
        let overview = HomeOverview(history: try [entry(-6, 2), entry(0, 5), entry(-7, 1), entry(1, 1)], needsRecovery: false, now: now, calendar: calendar)
        XCTAssertEqual(overview.days.count, 7)
        XCTAssertEqual(overview.daysCheckedIn, 2)
        XCTAssertEqual(try XCTUnwrap(overview.averageConnection), 3.5)
        let empty = HomeOverview(history: [], needsRecovery: false, now: now, calendar: calendar)
        XCTAssertNil(empty.averageConnection)
        XCTAssertEqual(empty.daysCheckedIn, 0)
    }

    func testHomeWeekUsesCalendarDaysAcrossDaylightSavingAndChangesAtMidnight() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Halifax"))
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-11-02T04:30:00Z"))
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: now))
        let entry = DailyCheckIn(date: yesterday, energy: 3, connection: 4, note: "", intention: "")
        let overview = HomeOverview(history: [entry], needsRecovery: false, now: now, calendar: calendar)
        XCTAssertEqual(Set(overview.days.map(\.date)).count, 7)
        XCTAssertEqual(overview.phase, .notStarted)
        XCTAssertEqual(overview.daysCheckedIn, 1)
    }

    func testCleanInstallIsEmptyUntilSamplesAreExplicitlyRequested() {
        defaults.removePersistentDomain(forName: suiteName)
        let store = HeartSyncStore(defaults: defaults)
        XCTAssertFalse(store.hasHistory)
        XCTAssertFalse(store.containsSampleData)
        XCTAssertEqual(store.partner.name, "Your partner")
        store.resetDemoData()
        XCTAssertTrue(store.hasHistory)
        XCTAssertTrue(HeartSyncStore(defaults: defaults).containsSampleData)
        store.clearAllHistory()
        XCTAssertFalse(HeartSyncStore(defaults: defaults).hasHistory)
        XCTAssertFalse(store.containsSampleData)
    }

    func testDraftAutosavesWithoutAViewAndReloadsBothResponses() {
        let store = HeartSyncStore(defaults: defaults)
        store.todayNote = "A draft survives app termination"
        store.todayEnergy = 2
        let reloaded = HeartSyncStore(defaults: defaults)
        XCTAssertEqual(reloaded.todayNote, "A draft survives app termination")
        XCTAssertEqual(reloaded.todayEnergy, 2)
        XCTAssertNil(reloaded.recoveryMessage)
    }

    func testCorruptVersionedStateIsPreservedUntilRecoveryIsChosen() {
        let corrupt = Data("unreadable".utf8)
        defaults.set(corrupt, forKey: "heartsync.state.v1")
        let store = HeartSyncStore(defaults: defaults)
        XCTAssertNotNil(store.recoveryMessage)
        XCTAssertFalse(store.hasHistory)
        store.todayNote = "Do not overwrite corrupted data"
        store.resetDemoData()
        XCTAssertEqual(defaults.data(forKey: "heartsync.state.v1"), corrupt)
        store.startFreshAfterRecovery()
        XCTAssertNil(store.recoveryMessage)
        XCTAssertEqual(defaults.data(forKey: "heartsync.recovery.unreadable"), corrupt)
        XCTAssertFalse(HeartSyncStore(defaults: defaults).hasHistory)
    }

    func testInvalidBackupIsRejectedWithoutPartialReplacement() throws {
        let store = HeartSyncStore(defaults: defaults)
        let original = store.history
        let originalPartner = store.partner.name
        let json = try XCTUnwrap(store.backupExportText.data(using: .utf8))
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: json) as? [String: Any])
        payload["partner"] = ["name": "Must not apply", "milestone": "", "supportFocus": ""]
        payload["draftEnergy"] = 999
        let bad = String(decoding: try JSONSerialization.data(withJSONObject: payload), as: UTF8.self)
        XCTAssertFalse(store.restoreFromBackupText(bad).isSuccess)
        XCTAssertEqual(store.history, original)
        XCTAssertEqual(store.partner.name, originalPartner)
        payload["draftEnergy"] = 3
        payload["schemaVersion"] = 99
        let future = String(decoding: try JSONSerialization.data(withJSONObject: payload), as: UTF8.self)
        XCTAssertFalse(store.restoreFromBackupText(future).isSuccess)
    }

    func testDuplicateHistoryAndPartnerRatingsAreRejected() throws {
        let store = HeartSyncStore(defaults: defaults)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var payload = try decoder.decode(HeartSyncBackupExport.self, from: Data(store.backupExportText.utf8))
        let first = try XCTUnwrap(payload.history.first)
        payload = HeartSyncBackupExport(exportedAt: payload.exportedAt, partner: payload.partner,
            history: [first, first], draftEnergy: 3, draftConnection: 3, draftNote: "", draftIntention: "")
        let encoder = JSONEncoder.iso8601
        XCTAssertFalse(store.restoreFromBackupText(String(decoding: try encoder.encode(payload), as: UTF8.self)).isSuccess)
        var entry = first
        entry.partnerResponse = PartnerCheckIn(energy: -1, connection: 3, note: "", intention: "")
        XCTAssertFalse(HeartSyncValidation.history([entry]))
    }

    func testPartnerCheckInPersistsAndSurvivesEditingFirstResponse() {
        let store = HeartSyncStore(defaults: defaults)
        store.clearAllHistory()
        XCTAssertFalse(store.submitPartnerCheckIn(energy: 3, connection: 3, note: "", intention: ""))
        store.todayNote = "First perspective"
        store.submitCheckIn()
        XCTAssertFalse(store.submitPartnerCheckIn(energy: 0, connection: 3, note: "", intention: ""))
        XCTAssertTrue(store.submitPartnerCheckIn(energy: 2, connection: 4, note: "  Partner perspective  ", intention: "  Take a walk  "))
        XCTAssertEqual(store.todayCheckIn?.note, "First perspective")
        XCTAssertEqual(store.todayCheckIn?.partnerResponse?.note, "Partner perspective")
        let loaded = HeartSyncStore(defaults: defaults)
        XCTAssertEqual(loaded.todayCheckIn?.partnerResponse?.intention, "Take a walk")
        loaded.todayNote = "Edited first perspective"
        loaded.submitCheckIn()
        XCTAssertEqual(loaded.todayCheckIn?.partnerResponse?.connection, 4)
        XCTAssertEqual(loaded.history.count, 1)
        let backup = loaded.backupExportText
        loaded.clearAllHistory()
        XCTAssertTrue(loaded.restoreFromBackupText(backup).isSuccess)
        XCTAssertEqual(loaded.todayCheckIn?.partnerResponse?.energy, 2)
    }

    func testLegacyCheckInDecodesWithoutPartnerResponse() throws {
        let legacy = """
        {"id":"EE0F3625-F325-4B1A-81CF-47D6EAD70AB3","date":0,"energy":3,"connection":4,"note":"Legacy","intention":"Listen"}
        """
        let entry = try JSONDecoder().decode(DailyCheckIn.self, from: Data(legacy.utf8))
        XCTAssertNil(entry.partnerResponse)
        XCTAssertNil(CoupleDailySummary(entry: entry))
    }

    func testCoupleSummaryRespondsToLowEnergyAndDifferentPerspectives() throws {
        var entry = DailyCheckIn(date: .now, energy: 4, connection: 5, note: "", intention: "")
        entry.partnerResponse = PartnerCheckIn(energy: 4, connection: 2, note: "", intention: "")
        let summary = try XCTUnwrap(CoupleDailySummary(entry: entry))
        XCTAssertEqual(summary.connectionGap, 3)
        XCTAssertEqual(summary.averageConnection, 3.5)
        XCTAssertTrue(summary.conversationPrompt.contains("differently"))
        entry.partnerResponse?.energy = 1
        XCTAssertTrue(try XCTUnwrap(CoupleDailySummary(entry: entry)).conversationPrompt.contains("running low"))
        entry.partnerResponse?.energy = 5
        entry.partnerResponse?.connection = 5
        XCTAssertTrue(try XCTUnwrap(CoupleDailySummary(entry: entry)).conversationPrompt.contains("appreciated"))
    }

    func testPreviewStoresKeepEditsAndEmptyHistoryIsolated() {
        let first = HeartSyncStore.makePreview(defaults: defaults)
        first.clearAllHistory()
        first.updatePartner(name: "Preview edit", milestone: "Preview", supportFocus: "Preview")

        let secondDefaults = HeartSyncStore.makePreviewDefaults()
        let emptyDefaults = HeartSyncStore.makePreviewDefaults()
        defer {
            // Remove any persisted preview edits from this test's temporary suites.
            for previewDefaults in [secondDefaults, emptyDefaults] {
                for key in previewDefaults.dictionaryRepresentation().keys where key.hasPrefix("heartsync.") {
                    previewDefaults.removeObject(forKey: key)
                }
            }
        }
        let second = HeartSyncStore.makePreview(defaults: secondDefaults)
        XCTAssertTrue(second.hasHistory)
        XCTAssertEqual(second.partner.name, HeartSyncSampleData.partner.name)
        XCTAssertEqual(secondDefaults.bool(forKey: "heartsync.shouldShowOnboarding"), false)
        XCTAssertTrue(secondDefaults.bool(forKey: "heartsync.hasAcknowledgedEmptyHistory"))

        let empty = HeartSyncStore.makePreview(defaults: emptyDefaults, emptyHistory: true)
        XCTAssertFalse(empty.hasHistory)
        XCTAssertTrue(second.hasHistory)
        XCTAssertEqual(first.partner.name, "Preview edit")
    }

    func testSubmitCheckInPersistsTrimmedEntryAndRetainsDraftForSafeEditing() {
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
        XCTAssertEqual(store.todayNote, "  Needed a calmer conversation tonight.  ")
        XCTAssertEqual(store.todayIntention, "  Protect 15 minutes after dinner.  ")
        XCTAssertTrue(store.submitCheckIn())
        XCTAssertEqual(store.todayCheckIn?.note, "Needed a calmer conversation tonight.")

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
        defaults.removeObject(forKey: "heartsync.state.v1")
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
