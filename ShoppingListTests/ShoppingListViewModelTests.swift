import UIKit
import XCTest
@testable import ShoppingList

final class ShoppingListViewModelTests: XCTestCase {

    // MARK: - Public Methods
    func testCheckAllIsDisabledWhileProductNameIsBeingEdited() {
        let list = makeList(completed: false, checked: false)
        let storage = MockStorageService(list: list)
        let viewModel = ShoppingListViewModel(
            coordinator: MockCoordinator(storageService: storage),
            listInfo: list.info
        )

        viewModel.viewWillAppear()
        let itemID = viewModel.getCellParams(for: 0).1.id
        XCTAssertTrue(viewModel.getCheckAllSwitchAvailability())

        viewModel.textFieldDidBeginEditing(cellID: itemID)
        XCTAssertFalse(viewModel.getCheckAllSwitchAvailability())

        viewModel.checkAllSwitchIs(on: true)
        XCTAssertFalse(viewModel.getBottomButtonState())

        viewModel.updateShoppingListItem(cellID: itemID, with: "Milk")
        XCTAssertTrue(viewModel.getCheckAllSwitchAvailability())
    }

    func testCompletedListKeepsLastProductReadOnly() throws {
        let list = makeList(completed: true, checked: true)
        let storage = MockStorageService(list: list)
        let viewModel = ShoppingListViewModel(
            coordinator: MockCoordinator(storageService: storage),
            listInfo: list.info
        )

        viewModel.viewWillAppear()
        viewModel.deleteItemButtonPressed(in: 0)
        viewModel.tableFinishedUpdating()

        XCTAssertEqual(viewModel.getTableRowCount(), 1)
        let cell = viewModel.getCellParams(for: 0)
        if case .button = cell.0 {
            XCTFail("The last product was treated as the add button")
        }
        XCTAssertFalse(cell.1.isEditable)
        XCTAssertEqual(storage.list.items.count, 1)
    }

    func testReloadDoesNotDuplicateProducts() {
        let list = makeList(completed: false, checked: false)
        let storage = MockStorageService(list: list)
        let viewModel = ShoppingListViewModel(
            coordinator: MockCoordinator(storageService: storage),
            listInfo: list.info
        )

        viewModel.viewWillAppear()
        viewModel.viewWillAppear()

        XCTAssertEqual(viewModel.getTableRowCount(), 2)
    }

    func testCompletionButtonRequiresAllProductsChecked() {
        let list = makeList(completed: false, checked: false)
        let storage = MockStorageService(list: list)
        let viewModel = ShoppingListViewModel(
            coordinator: MockCoordinator(storageService: storage),
            listInfo: list.info
        )

        viewModel.viewWillAppear()
        XCTAssertFalse(viewModel.getBottomButtonState())

        viewModel.checkAllSwitchIs(on: true)
        XCTAssertTrue(viewModel.getBottomButtonState())
    }

    func testNewProductRequestsEditingAtInsertedRow() {
        let list = makeList(completed: false, checked: false)
        let storage = MockStorageService(list: list)
        let viewModel = ShoppingListViewModel(
            coordinator: MockCoordinator(storageService: storage),
            listInfo: list.info
        )

        viewModel.viewWillAppear()
        viewModel.addNewItemButtonPressed()

        XCTAssertEqual(viewModel.getTableRowCount(), 3)
        XCTAssertFalse(viewModel.getCheckAllSwitchAvailability())
        XCTAssertTrue(viewModel.getCellParams(for: 1).1.startEditing)
    }

    // MARK: - Private Methods
    private func makeList(completed: Bool, checked: Bool) -> ShopList {
        ShopList(
            info: ListInfo(
                listId: UUID(),
                title: "Test list",
                date: Date(),
                completed: completed,
                pinned: false
            ),
            items: [ListItem(name: "Milk", quantity: 1, unit: Units.liter.rawValue, checked: checked)]
        )
    }
}

private final class MockCoordinator: Coordinator {

    var currentLanguage = 0
    var currentTheme = AppTheme.automatic
    let notificationService: NotificationServiceProtocol = MockNotificationService()
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

private final class MockNotificationService: NotificationServiceProtocol {

    func cancelNotification(for listID: UUID) {}
    func scheduleNotification(for listID: UUID, listTitle: String, date: Date) async throws {}
}

private final class MockStorageService: StorageServiceProtocol {

    var list: ShopList

    init(list: ShopList) {
        self.list = list
    }

    func deleteList(with id: UUID) throws {}
    func deleteLists(with ids: [UUID]) throws {}
    func getExistingListNames(excluding listID: UUID?) throws -> Set<String> { [list.info.title.lowercased()] }
    func getItems(by listId: UUID) throws -> [ListItem] { list.items }
    func getList(by id: UUID) throws -> ShopList? { list.info.listId == id ? list : nil }
    func getListsWithStatus(isCompleted: Bool) throws -> [ListInfo] { [list.info] }

    func restoreList(with id: UUID) throws {
        list = ShopList(
            info: ListInfo(
                listId: list.info.listId,
                title: list.info.title,
                date: Date(),
                completed: false,
                pinned: false
            ),
            items: list.items.map {
                ListItem(name: $0.name, quantity: $0.quantity, unit: $0.unit, checked: false)
            }
        )
    }

    func saveNewList(list: ShopList) throws { self.list = list }
    func updateList(list: ShopList) throws { self.list = list }
    func updateListInfo(listInfo: ListInfo) throws { list = ShopList(info: listInfo, items: list.items) }
}
