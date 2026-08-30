import XCTest
@testable import GotItAll

final class LanguageManagerTests: XCTestCase {

    // MARK: - Private Properties
    private var originalLanguage = 0

    // MARK: - Lifecycle
    override func setUp() {
        super.setUp()
        originalLanguage = LanguageManager.languageManager.currentLanguage
    }

    override func tearDown() {
        LanguageManager.languageManager.currentLanguage = originalLanguage
        super.tearDown()
    }

    // MARK: - Public Methods
    func testEnglishLanguageUsesEnglishBundle() {
        LanguageManager.languageManager.currentLanguage = 2

        XCTAssertEqual(String.buttonSettings, "Settings")
    }

    func testRussianLanguageUsesRussianBundle() {
        LanguageManager.languageManager.currentLanguage = 1

        XCTAssertEqual(String.buttonSettings, "Настройки")
    }

    func testSelectedLanguageIsReadBackFromPreferences() {
        LanguageManager.languageManager.currentLanguage = 2

        XCTAssertEqual(LanguageManager.languageManager.currentLanguage, 2)
    }
}
