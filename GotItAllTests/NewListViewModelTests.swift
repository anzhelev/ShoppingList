import XCTest
@testable import GotItAll

final class NewListViewModelTests: XCTestCase {

    // MARK: - Public Methods
    func testEmptyProductShowsValidationErrorAfterEditingEnds() {
        let viewModel = makeViewModel()
        viewModel.viewWillAppear()
        viewModel.updateNewListTitle(with: "Weekly shopping")
        viewModel.addNewItemButtonPressed()
        let productID = viewModel.getCellParams(for: 1).1.id

        viewModel.updateNewListItem(id: productID, with: "")

        XCTAssertEqual(viewModel.getCellParams(for: 1).1.error, String.newListEmptyName)
    }

    func testInitialListTitleDoesNotShowValidationError() {
        let viewModel = makeViewModel()

        viewModel.viewWillAppear()

        XCTAssertNil(viewModel.getCellParams(for: 0).1.error)
    }

    func testNewProductDoesNotShowValidationErrorBeforeFirstInput() {
        let viewModel = makeViewModel()
        viewModel.viewWillAppear()
        viewModel.updateNewListTitle(with: "Weekly shopping")

        viewModel.addNewItemButtonPressed()

        XCTAssertNil(viewModel.getCellParams(for: 1).1.error)
        XCTAssertEqual(viewModel.getCellParams(for: 1).1.startEditing, true)
    }

    func testValidListIsSavedOnlyAfterSaveButtonPressed() {
        let storage = NewListMockStorageService()
        let viewModel = NewListViewModel(
            coordinator: NewListMockCoordinator(storageService: storage),
            editList: nil
        )
        viewModel.viewWillAppear()

        viewModel.updateNewListTitle(with: "Weekly shopping")

        XCTAssertTrue(storage.savedLists.isEmpty)

        viewModel.completeButtonPressed()

        XCTAssertEqual(storage.savedLists.count, 1)
        XCTAssertEqual(storage.savedLists.first?.info.title, "Weekly shopping")
    }

    // MARK: - Private Methods
    private func makeViewModel() -> NewListViewModel {
        NewListViewModel(
            coordinator: NewListMockCoordinator(storageService: NewListMockStorageService()),
            editList: nil
        )
    }
}

private final class NewListMockCoordinator: Coordinator {

    var currentLanguage = 0
    var currentTheme = AppTheme.automatic
    let notificationService: NotificationServiceProtocol = NewListMockNotificationService()
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

private final class NewListMockNotificationService: NotificationServiceProtocol {

    func cancelNotification(for listID: UUID) {}
    func scheduleNotification(for listID: UUID, listTitle: String, date: Date) async throws {}
}

private final class NewListMockStorageService: StorageServiceProtocol {

    // MARK: - Public Properties
    var savedLists: [ShopList] = []

    // MARK: - Public Methods
    func deleteList(with id: UUID) throws {}
    func deleteLists(with ids: [UUID]) throws {}
    func getExistingListNames(excluding listID: UUID?) throws -> Set<String> { [] }
    func getItems(by listId: UUID) throws -> [ListItem] { [] }
    func getList(by id: UUID) throws -> ShopList? { nil }
    func getListsWithStatus(isCompleted: Bool) throws -> [ListInfo] { [] }
    func restoreList(with id: UUID) throws {}
    func saveNewList(list: ShopList) throws { savedLists.append(list) }
    func updateList(list: ShopList) throws {}
    func updateListInfo(listInfo: ListInfo) throws {}
}
