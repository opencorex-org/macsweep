import XCTest

final class SettingsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSettingsNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.exists)
    }
}
