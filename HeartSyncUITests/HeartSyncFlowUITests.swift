import XCTest

final class HeartSyncFlowUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(samples: Bool = false, largeType: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset", "--skip-onboarding"]
        if samples { app.launchArguments.append("--samples") }
        if largeType { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        return app
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable, "Element should be reachable by scrolling: \(element)")
    }

    private func seekProfile(_ element: XCUIElement, in app: XCUIApplication, upward: Bool) {
        for _ in 0..<14 {
            if element.exists && element.isHittable { return }
            // Drag in the form's margin so a nested JSON editor cannot consume the scroll.
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: upward ? 0.75 : 0.30))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: upward ? 0.30 : 0.75))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(element.exists && element.isHittable, "Profile control must be reachable: \(element)")
    }

    private func assertWithinScreenWidth(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertGreaterThanOrEqual(element.frame.minX, app.frame.minX, "Leading edge must not be clipped")
        XCTAssertLessThanOrEqual(element.frame.maxX, app.frame.maxX, "Trailing edge must not be clipped")
    }

    private func screenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCancelClearThenRestorePairedBackupAndRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset", "--skip-onboarding", "--samples", "--paired-samples"]
        app.launch()
        XCTAssertTrue(app.buttons["home.primaryAction"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["home.primaryAction"].label.contains("View your shared check-in"))
        app.tabBars.buttons["Profile"].tap()
        let copy = app.buttons["backup.copy"]
        seekProfile(copy, in: app, upward: true)
        copy.tap()
        let clear = app.buttons["data.clearHistory"]
        seekProfile(clear, in: app, upward: true)
        clear.tap()
        app.buttons["Cancel"].tap()
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.buttons["home.primaryAction"].label.contains("View your shared check-in"))

        app.tabBars.buttons["Profile"].tap()
        seekProfile(clear, in: app, upward: true)
        clear.tap()
        app.buttons["Clear history"].tap()
        let notNow = app.buttons["Not now"]
        XCTAssertTrue(notNow.waitForExistence(timeout: 10))
        notNow.tap()
        let paste = app.buttons["backup.paste"]
        seekProfile(paste, in: app, upward: false)
        paste.tap()
        let restore = app.buttons["backup.restore"]
        seekProfile(restore, in: app, upward: true)
        XCTAssertTrue(restore.isEnabled)
        restore.tap()
        app.buttons["Restore backup"].tap()
        let status = app.staticTexts["backup.restoreStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("Backup restored"))
        screenshot(app, name: "Restore result remains beside backup controls")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--skip-onboarding"]
        app.launch()
        XCTAssertTrue(app.buttons["home.primaryAction"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["home.primaryAction"].label.contains("View your shared check-in"))
        reveal(app.buttons["home.primaryAction"], in: app)
        app.buttons["home.primaryAction"].tap()
        XCTAssertTrue(app.staticTexts["Fictional partner perspective"].exists)
    }

    func testRecoveryDisablesUnavailableActionsAndExplicitFreshStartPersists() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset", "--skip-onboarding", "--unreadable-state"]
        app.launch()
        let primary = app.buttons["home.primaryAction"]
        XCTAssertTrue(primary.waitForExistence(timeout: 15))
        XCTAssertTrue(primary.label.contains("Recover saved data"))
        reveal(primary, in: app)
        primary.tap()
        XCTAssertFalse(app.buttons["profile.save"].isEnabled)
        let reset = app.buttons["data.resetSamples"]
        seekProfile(reset, in: app, upward: true)
        XCTAssertFalse(reset.isEnabled)
        let clear = app.buttons["data.clearHistory"]
        seekProfile(clear, in: app, upward: true)
        XCTAssertFalse(clear.isEnabled)
        XCTAssertFalse(app.buttons["data.clearDraft"].isEnabled)
        let fresh = app.buttons["recovery.startFresh"]
        seekProfile(fresh, in: app, upward: false)
        fresh.tap()
        app.buttons["recovery.confirmFresh"].tap()
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(primary.label.contains("Start today’s check-in"))
        app.terminate()
        app.launchArguments = ["--ui-testing", "--skip-onboarding"]
        app.launch()
        XCTAssertTrue(primary.waitForExistence(timeout: 15))
        XCTAssertTrue(primary.label.contains("Start today’s check-in"))
    }

    func testProfileValidationAndRelaunchKeepTheLastSavedName() {
        let app = launch()
        app.tabBars.buttons["Profile"].tap()
        let name = app.textFields["profile.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        let original = name.value as? String ?? ""
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: original.count) + "Taylor")
        app.buttons["profile.keyboardDone"].tap()
        app.buttons["profile.save"].tap()
        XCTAssertTrue(app.staticTexts["profile.status"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["profile.status"].label, "Profile saved locally.")

        name.tap()
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 6) + String(repeating: "x", count: 201))
        app.buttons["profile.keyboardDone"].tap()
        app.buttons["profile.save"].tap()
        XCTAssertTrue(app.staticTexts["profile.status"].label.contains("Profile was not saved"))
        screenshot(app, name: "Profile validation explains unsaved input")

        app.terminate()
        app.launchArguments = ["--ui-testing", "--skip-onboarding"]
        app.launch()
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        XCTAssertEqual(name.value as? String, "Taylor")
    }

    func testFirstLaunchStartsCheckInWithoutAnEmptyHistoryDetour() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset"]
        app.launch()
        let start = app.buttons["onboarding.primary"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        reveal(start, in: app)
        start.tap()
        XCTAssertTrue(app.navigationBars["Check-In"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["checkIn.save"].exists)
        XCTAssertFalse(app.staticTexts["Moments history was cleared"].exists)
    }

    func testCouplesCheckInConsentSummaryAndRelaunch() {
        let app = launch()
        let start = app.buttons["home.primaryAction"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        reveal(start, in: app)
        start.tap()
        let reflection = app.descendants(matching: .any).matching(identifier: "checkIn.note").firstMatch
        reveal(reflection, in: app)
        reflection.tap()
        reflection.typeText("We made time to listen.")
        app.buttons["keyboard.done"].tap()
        app.buttons["checkIn.save"].tap()
        XCTAssertTrue(app.buttons["checkIn.continueTogether"].waitForExistence(timeout: 5))
        app.buttons["checkIn.continueTogether"].tap()
        let savePartner = app.buttons["couple.save"]
        reveal(savePartner, in: app)
        XCTAssertFalse(savePartner.isEnabled)
        let consent = app.switches["couple.consent"]
        reveal(consent, in: app)
        // SwiftUI exposes the entire labelled row as the switch. Tap its trailing control,
        // not the centre of the long consent label.
        consent.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        let agreed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == '1'"), object: consent)
        XCTAssertEqual(XCTWaiter.wait(for: [agreed], timeout: 5), .completed)
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: savePartner)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 5), .completed)
        reveal(savePartner, in: app)
        XCTAssertTrue(savePartner.isEnabled)
        savePartner.tap()
        XCTAssertTrue(app.staticTexts["couple.summary"].waitForExistence(timeout: 5))
        screenshot(app, name: "Both perspectives and conversation prompt")
        app.navigationBars["Together"].buttons["Done"].tap()
        app.terminate()
        app.launchArguments = ["--ui-testing", "--skip-onboarding"]
        app.launch()
        let shared = app.buttons["home.primaryAction"]
        XCTAssertTrue(shared.waitForExistence(timeout: 15))
        reveal(shared, in: app)
        shared.tap()
        XCTAssertTrue(app.staticTexts["couple.summary"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "We made time to listen.")).firstMatch.exists)
    }

    func testEmptyAndSampleHomesAtAccessibilityTextSize() {
        var app = launch(largeType: true)
        let start = app.buttons["home.primaryAction"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        reveal(start, in: app)
        XCTAssertTrue(start.isHittable)
        assertWithinScreenWidth(start, in: app)
        screenshot(app, name: "Empty home at accessibility text size")
        app.terminate()
        app = launch(samples: true, largeType: true)
        let shared = app.buttons["home.primaryAction"]
        XCTAssertTrue(shared.waitForExistence(timeout: 15))
        reveal(shared, in: app)
        XCTAssertTrue(shared.isHittable)
        assertWithinScreenWidth(shared, in: app)
        screenshot(app, name: "Fictional sample home at accessibility text size")
    }
}
