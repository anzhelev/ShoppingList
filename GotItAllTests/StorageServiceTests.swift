import CoreData
import XCTest
@testable import GotItAll

final class StorageServiceTests: XCTestCase {

    // MARK: - Private Properties
    private var container: NSPersistentContainer!
    private var storageService: StorageService!

    // MARK: - Lifecycle
    override func setUpWithError() throws {
        try super.setUpWithError()

        guard let model = NSManagedObjectModel.mergedModel(from: nil) else {
            XCTFail("Core Data model is unavailable")
            return
        }

        container = NSPersistentContainer(name: "ShoppingList", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]

        let expectation = expectation(description: "Persistent store loaded")
        var loadingError: Error?
        container.loadPersistentStores { _, error in
            loadingError = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
        if let loadingError {
            throw loadingError
        }
        storageService = StorageService(context: container.viewContext)
    }

    override func tearDownWithError() throws {
        storageService = nil
        container = nil
        try super.tearDownWithError()
    }

    // MARK: - Public Methods
    func testItemOrderIsPreserved() throws {
        let list = makeList(
            items: [
                ListItem(name: "Third", quantity: 3, unit: Units.piece.rawValue, checked: false),
                ListItem(name: "First", quantity: 1, unit: Units.kg.rawValue, checked: false),
                ListItem(name: "Second", quantity: 2, unit: Units.pack.rawValue, checked: true)
            ]
        )

        try storageService.saveNewList(list: list)

        XCTAssertEqual(try storageService.getItems(by: list.info.listId).map(\.name), ["Third", "First", "Second"])
    }

    func testRestoreResetsStateAndKeepsItems() throws {
        let reminderDate = Date().addingTimeInterval(3_600)
        let list = makeList(completed: true, pinned: true, reminderDate: reminderDate)
        try storageService.saveNewList(list: list)

        try storageService.restoreList(with: list.info.listId)

        let restoredList = try XCTUnwrap(storageService.getList(by: list.info.listId))
        XCTAssertFalse(restoredList.info.completed)
        XCTAssertFalse(restoredList.info.pinned)
        XCTAssertNil(restoredList.info.reminderDate)
        XCTAssertEqual(restoredList.items.count, list.items.count)
        XCTAssertTrue(restoredList.items.allSatisfy { !$0.checked })
    }

    func testUpdatingCompletedListPreservesSingleItem() throws {
        let original = makeList(
            completed: true,
            items: [ListItem(name: "Milk", quantity: 1, unit: Units.liter.rawValue, checked: true)]
        )
        try storageService.saveNewList(list: original)

        let updated = ShopList(
            info: original.info,
            items: [ListItem(name: "Milk", quantity: 2, unit: Units.liter.rawValue, checked: true)]
        )
        try storageService.updateList(list: updated)

        let storedList = try XCTUnwrap(storageService.getList(by: original.info.listId))
        XCTAssertEqual(storedList.items.count, 1)
        XCTAssertEqual(storedList.items.first?.quantity, 2)
    }

    // MARK: - Private Methods
    private func makeList(
        completed: Bool = false,
        pinned: Bool = false,
        reminderDate: Date? = nil,
        items: [ListItem] = [
            ListItem(name: "Milk", quantity: 1, unit: Units.liter.rawValue, checked: true),
            ListItem(name: "Bread", quantity: 1, unit: Units.piece.rawValue, checked: false)
        ]
    ) -> ShopList {
        ShopList(
            info: ListInfo(
                listId: UUID(),
                title: "Test list",
                date: Date(),
                completed: completed,
                pinned: pinned,
                reminderDate: reminderDate
            ),
            items: items
        )
    }
}
