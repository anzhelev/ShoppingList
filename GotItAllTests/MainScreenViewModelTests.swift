import XCTest
@testable import GotItAll

final class MainScreenViewModelTests: XCTestCase {

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
    func testDateUsesEnglishApplicationLocale() {
        LanguageManager.languageManager.currentLanguage = 2
        let viewModel = makeViewModel()

        viewModel.viewWillAppear()

        XCTAssertEqual(viewModel.getCellParams(for: 0).date, "12.31.2026")
    }

    func testDateUsesRussianApplicationLocale() {
        LanguageManager.languageManager.currentLanguage = 1
        let viewModel = makeViewModel()

        viewModel.viewWillAppear()

        XCTAssertEqual(viewModel.getCellParams(for: 0).date, "31.12.2026")
    }

    // MARK: - Private Methods
    private func makeViewModel() -> MainScreenViewModel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        let date = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 12)) ?? Date()
        let list = ListInfo(
            listId: UUID(),
            title: "Test list",
            date: date,
            completed: false,
            pinned: false
        )
        let storage = MainScreenMockStorageService(list: list)
        return MainScreenViewModel(
            coordinator: MainScreenMockCoordinator(storageService: storage),
            completeMode: false
        )
    }
}

private final class MainScreenMockCoordinator: Coordinator {

    var currentLanguage = 0
    var currentTheme = AppTheme.automatic
    let notificationService: NotificationServiceProtocol = MainScreenMockNotificationService()
    let storageService: StorageServiceProtocol

    init(storageService: StorageServiceProtocol) {
        self.storageService = storageService
    }

    func applyCurrentTheme() {}
    func dismissPopupVC(completion: (() -> Void)?) { completion?() }
    func getLanguages() -> [Language] { [] }
    func popToMainView() {}
    func showAlert(title: String, message: String) {}
    func showDatePickerView(delegate: DatePickerViewDelegate) {}
    func showNotificationPermissionAlert() {}
    func showOnboarding() {}
    func showSuccessView(delegate: SuccessViewDelegate) {}
    func showTabBarVC() {}
    func showWelcomeScreen() {}
    func start() {}
    func switchToListEditionView(editList: UUID?) {}
    func switchToMainView() {}
    func switchToNewListCreationView() {}
    func switchToShoppingList(with listInfo: ListInfo) {}
}

private final class MainScreenMockNotificationService: NotificationServiceProtocol {

    func cancelNotification(for listID: UUID) {}
    func scheduleNotification(for listID: UUID, listTitle: String, date: Date) async throws {}
}

private final class MainScreenMockStorageService: StorageServiceProtocol {

    // MARK: - Private Properties
    private let list: ListInfo

    // MARK: - Initializers
    init(list: ListInfo) {
        self.list = list
    }

    // MARK: - Public Methods
    func deleteList(with id: UUID) throws {}
    func deleteLists(with ids: [UUID]) throws {}
    func getExistingListNames(excluding listID: UUID?) throws -> Set<String> { [] }
    func getItems(by listId: UUID) throws -> [ListItem] { [] }
    func getList(by id: UUID) throws -> ShopList? { nil }
    func getListsWithStatus(isCompleted: Bool) throws -> [ListInfo] { [list] }
    func restoreList(with id: UUID) throws {}
    func saveNewList(list: ShopList) throws {}
    func updateList(list: ShopList) throws {}
    func updateListInfo(listInfo: ListInfo) throws {}
}
