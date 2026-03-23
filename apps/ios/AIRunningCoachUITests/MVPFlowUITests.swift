import XCTest

final class MVPFlowUITests: XCTestCase {
    func testMainFlowShowsNextWorkoutAndLetsUserSubmitFeedback() {
        let app = XCUIApplication()
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
