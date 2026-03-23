import XCTest

final class MVPFlowUITests: XCTestCase {
    func testSetupGuideCanBeSkippedAndReopenedFromProfile() {
        let app = XCUIApplication()
        app.launchArguments += ["UITest.ResetSetupGuide"]
        app.launch()

        XCTAssertTrue(app.staticTexts["setup.guide.title"].waitForExistence(timeout: 5))
        app.buttons["setup.guide.skip"].tap()

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
