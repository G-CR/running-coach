import XCTest

final class MVPFlowUITests: XCTestCase {
    func testSetupGuideRequiresKeyStepsBeforeStepThree() {
        let app = XCUIApplication()
        app.launchArguments += [
            "UITest.SkipSetupGuide",
            "UITest.MockHealthKitAuthorized",
            "UITest.MockAPIHealthy",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["home.nextWorkout.title"].waitForExistence(timeout: 5))

        app.tabBars.buttons["我的"].tap()
        let reopenGuideButton = app.buttons["profile.reopenSetupGuide"]
        if reopenGuideButton.waitForExistence(timeout: 2) {
            reopenGuideButton.tap()
        } else {
            app.swipeUp()
            if app.buttons["重新打开首次引导"].waitForExistence(timeout: 2) {
                app.buttons["重新打开首次引导"].tap()
            } else {
                app.staticTexts["重新打开首次引导"].tap()
            }
        }

        XCTAssertTrue(app.staticTexts["setup.guide.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["setup.guide.primary"].isEnabled)

        app.buttons["setup.guide.primary"].tap()
        XCTAssertTrue(app.staticTexts["检查 API"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["setup.guide.primary"].isEnabled)

        app.buttons["setup.guide.api.check"].tap()
        XCTAssertTrue(app.staticTexts["API 连通正常"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["setup.guide.primary"].isEnabled)

        app.buttons["setup.guide.primary"].tap()
        XCTAssertTrue(app.staticTexts["首次同步"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["setup.guide.primary"].isEnabled)
        XCTAssertFalse(app.buttons["setup.guide.skip"].exists)

        app.buttons["setup.guide.sync.action"].tap()
        let primaryEnabled = NSPredicate(format: "isEnabled == true")
        expectation(for: primaryEnabled, evaluatedWith: app.buttons["setup.guide.primary"])
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.buttons["setup.guide.skip"].waitForExistence(timeout: 5))
    }

    func testMainFlowShowsNextWorkoutAndLetsUserSubmitFeedback() {
        let app = XCUIApplication()
        app.launchArguments += ["UITest.SkipSetupGuide"]
        app.launch()

        XCTAssertTrue(app.staticTexts["home.nextWorkout.title"].waitForExistence(timeout: 5))

        app.tabBars.buttons["训练"].tap()
        app.buttons["workout.list.first"].tap()
        app.buttons["workout.detail.feedback"].tap()
        app.buttons["feedback.submit"].tap()

        app.tabBars.buttons["首页"].tap()
        XCTAssertTrue(app.staticTexts["home.todo.feedback.complete"].waitForExistence(timeout: 5))
    }
}
