import CoreData
import Foundation

enum StorageServiceError: LocalizedError {

    // MARK: - Constants
    case listAlreadyExists
    case listNotFound

    // MARK: - Public Properties
    var errorDescription: String? {
        switch self {
        case .listAlreadyExists:
            return .storageListAlreadyExists
        case .listNotFound:
            return .storageListNotFound
        }
    }
}

protocol StorageServiceProtocol {
    func deleteList(with id: UUID) throws
    func deleteLists(with ids: [UUID]) throws
    func getExistingListNames(excluding listID: UUID?) throws -> Set<String>
    func getItems(by listId: UUID) throws -> [ListItem]
    func getList(by id: UUID) throws -> ShopList?
    func getListsWithStatus(isCompleted: Bool) throws -> [ListInfo]
    func restoreList(with id: UUID) throws
    func saveNewList(list: ShopList) throws
    func updateList(list: ShopList) throws
    func updateListInfo(listInfo: ListInfo) throws
}

final class StorageService: StorageServiceProtocol {

    // MARK: - Private Properties
    private let coreDataService: CoreDataService

    // MARK: - Initializers
    init(context: NSManagedObjectContext = AppDelegate.context) {
        coreDataService = CoreDataService(context: context)
    }

    // MARK: - Public Methods
    func deleteList(with id: UUID) throws {
        try coreDataService.deleteListFromStore(with: id)
    }

    func deleteLists(with ids: [UUID]) throws {
        try coreDataService.deleteListsFromStore(with: ids)
    }

    func getExistingListNames(excluding listID: UUID? = nil) throws -> Set<String> {
        let lists = try getListsWithStatus(isCompleted: false)
        return Set(
            lists
                .filter { $0.listId != listID }
                .map { normalizeName($0.title) }
        )
    }

    func getItems(by listId: UUID) throws -> [ListItem] {
        try coreDataService.fetchItemsForList(with: listId)
    }

    func getList(by id: UUID) throws -> ShopList? {
        try coreDataService.fetchList(with: id)
    }

    func getListsWithStatus(isCompleted: Bool) throws -> [ListInfo] {
        try coreDataService.fetchListsWith(status: isCompleted)
    }

    func restoreList(with id: UUID) throws {
        try coreDataService.restoreList(with: id)
    }

    func saveNewList(list: ShopList) throws {
        try coreDataService.addNewListToStore(list: list)
    }

    func updateList(list: ShopList) throws {
        try coreDataService.updateListInStore(list: list)
    }

    func updateListInfo(listInfo: ListInfo) throws {
        try coreDataService.updateListInfoInStore(listInfo: listInfo)
    }

    // MARK: - Private Methods
    private func normalizeName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
