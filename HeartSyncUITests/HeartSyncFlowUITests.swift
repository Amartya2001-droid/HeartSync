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

    private func screenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
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
        screenshot(app, name: "Empty home at accessibility text size")
        app.terminate()
        app = launch(samples: true, largeType: true)
        let shared = app.buttons["home.primaryAction"]
        XCTAssertTrue(shared.waitForExistence(timeout: 15))
        reveal(shared, in: app)
        XCTAssertTrue(shared.isHittable)
        screenshot(app, name: "Fictional sample home at accessibility text size")
    }
}
