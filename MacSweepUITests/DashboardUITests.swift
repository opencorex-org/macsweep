import XCTest

final class DashboardUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDashboardLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.exists)
    }
}
