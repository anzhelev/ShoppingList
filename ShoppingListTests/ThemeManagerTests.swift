import UIKit
import XCTest
@testable import ShoppingList

final class ThemeManagerTests: XCTestCase {

    // MARK: - Public Methods
    func testApplicationNameIsConsistent() {
        XCTAssertEqual(String.appName, "Got It All")
    }

    func testAutomaticThemeUsesDarkStyleAtNight() throws {
        let calendar = makeCalendar()
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 30, hour: 22)))

        XCTAssertEqual(AppTheme.automatic.interfaceStyle(for: date, calendar: calendar), .dark)
    }

    func testAutomaticThemeUsesLightStyleDuringDay() throws {
        let calendar = makeCalendar()
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 30, hour: 12)))

        XCTAssertEqual(AppTheme.automatic.interfaceStyle(for: date, calendar: calendar), .light)
    }

    // MARK: - Private Methods
    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }
}
