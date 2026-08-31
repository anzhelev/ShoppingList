import XCTest
@testable import GotItAll

final class DatePickerViewModelTests: XCTestCase {

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
    func testEnglishLanguageUsesEnglishPickerLocale() {
        LanguageManager.languageManager.currentLanguage = 2

        let delegate = DatePickerDelegateMock()
        let viewModel = DatePickerViewModel(delegate: delegate)

        XCTAssertEqual(viewModel.locale.identifier, "en")
    }

    func testRussianLanguageUsesRussianPickerLocale() {
        LanguageManager.languageManager.currentLanguage = 1

        let delegate = DatePickerDelegateMock()
        let viewModel = DatePickerViewModel(delegate: delegate)

        XCTAssertEqual(viewModel.locale.identifier, "ru")
    }
}

private final class DatePickerDelegateMock: DatePickerViewDelegate {

    func datePickerCancelButtonPressed() {}
    func datePickerConfirmButtonPressed(date: Date) {}
}
