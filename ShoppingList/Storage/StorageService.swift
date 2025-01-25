import CoreData

protocol StorageServiceProtocol {
    func getExistingListNames() -> Set<String>
    func getListsWithStatus(isCompleted: Bool) -> [ListInfo]
    func deleteList(with id: UUID)
    func getList(by id: UUID) -> ShopList?
    func saveNewList(list: ShopList)
    func updateListInfo(listInfo: ListInfo)
    func updateList(list: ShopList)
    func restoreList(with id: UUID)
    func getItems(by listId: UUID) -> [ListItem]?
}

final class StorageService: StorageServiceProtocol {
    // MARK: - Public Properties
    var context: NSManagedObjectContext = AppDelegate.context
    
    // MARK: - Private Properties
    private lazy var coreDataService: CoreDataService = CoreDataService(delegate: self)
    
    // MARK: - Public Methods
    func saveContext() {
        if let appDelegate = AppDelegate.appDelegate {
            appDelegate.saveContext()
        }
    }
    
    func getExistingListNames() -> Set<String> {
        Set(getListsWithStatus(isCompleted: false).map{ $0.title.lowercased() })
    }
    
    func getListsWithStatus(isCompleted: Bool) -> [ListInfo] {
        coreDataService.fetchListsWith(status: isCompleted)
    }
    
    func deleteList(with id: UUID) {
        coreDataService.deleteItemsFromList(list: id)
        coreDataService.deleteListFromStore(with: id)
    }
    
    func getList(by id: UUID) -> ShopList? {
        guard let list = coreDataService.fetchListCoreData(with: id) else {
            return nil
        }
        let listItems = coreDataService.fetchItemsForList(with: id)
        
        return .init(info: .init(listId: list.listId ?? UUID(),
                                 title: list.title ?? "",
                                 date: list.date ?? Date(),
                                 completed: list.completed,
                                 pinned: list.pinned
                                ),
                     items: listItems.map {item in
                .init(name: item.name ?? "",
                      quantity: item.quantity,
                      unit: item.unit ?? "",
                      checked: item.checked
                )
        })
    }
    
    func saveNewList(list: ShopList) {
        coreDataService.addNewListToStore(list: list.info)
        for item in list.items {
            coreDataService.addItemTolist(list: list.info.listId, item: item)
        }
    }
    
    func updateListInfo(listInfo: ListInfo) {
        coreDataService.updateListInfoInStore(listInfo: listInfo)
    }
    
    func updateList(list: ShopList) {
        deleteList(with: list.info.listId)
        saveNewList(list: list)
    }
    
    func restoreList(with id: UUID) {
        guard let oldList = getList(by: id) else {
            return
        }
        deleteList(with: id)
        saveNewList(list: .init(info: .init(listId: oldList.info.listId,
                                            title: oldList.info.title,
                                            date: oldList.info.date,
                                            completed: false,
                                            pinned: false
                                           ),
                                items: oldList.items.map {
            .init(name: $0.name,
                  quantity: $0.quantity,
                  unit: $0.unit,
                  checked: false
            )
        }
        )
        )
    }
    
    func getItems(by listId: UUID) -> [ListItem]? {
        let storedItems = coreDataService.fetchItemsForList(with: listId)
        return storedItems.map {item in
                .init(name: item.name ?? "",
                      quantity: item.quantity,
                      unit: item.unit ?? "",
                      checked: item.checked
                )
        }
    }
}
