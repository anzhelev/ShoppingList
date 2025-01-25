import CoreData

final class CoreDataService {
    // MARK: - Private Properties
    private weak var delegate: StorageService?
    private let context: NSManagedObjectContext
    
    // MARK: - Initializers
    init(delegate: StorageService) {
        self.delegate = delegate
        self.context = delegate.context
    }
    
    // MARK: - Public Methods
    func fetchListsWith(status isCompleted: Bool) -> [ListInfo] {
        let request = NSFetchRequest<ShoppingListCoreData>(entityName: "ShoppingListCoreData")
        request.predicate = NSPredicate(format: "completed == %@", NSNumber(value: isCompleted))
        guard let storedLists = try? context.fetch(request) else {
            return []
        }
        return storedLists.map { list in
                .init(listId: list.listId ?? UUID(),
                      title: list.title ?? "",
                      date: list.date ?? Date(),
                      completed: list.completed,
                      pinned: list.pinned
                )
        }
    }
    
    func fetchItemsForList(with id: UUID) -> [ListItemCoreData] {
        let request = NSFetchRequest<ListItemCoreData>(entityName: "ListItemCoreData")
        request.predicate = NSPredicate(format: "shoppingList.listId == %@", id as CVarArg)
        guard let storedItems = try? context.fetch(request) else {
            return []
        }
        return storedItems
    }
    
    func fetchListCoreData(with id: UUID) -> ShoppingListCoreData? {
        let request = NSFetchRequest<ShoppingListCoreData>(entityName: "ShoppingListCoreData")
        request.predicate = NSPredicate(format: "listId == %@", id as CVarArg)
        return try? context.fetch(request).first
    }
    
    func addNewListToStore(list: ListInfo) {
        let newListCoreData = ShoppingListCoreData(context: context)
        newListCoreData.listId = list.listId
        newListCoreData.title = list.title
        newListCoreData.date = list.date
        newListCoreData.completed = list.completed
        newListCoreData.pinned = list.pinned
        delegate?.saveContext()
    }
    
    func addItemTolist(list id: UUID, item: ListItem) {
        if let listCoreData = fetchListCoreData(with: id) {
            listCoreData.addToListItems(buildListItemCoreData(from: item))
            delegate?.saveContext()
        }
    }
    
    func updateListInfoInStore(listInfo: ListInfo) {
        let request = NSFetchRequest<ShoppingListCoreData>(entityName: "ShoppingListCoreData")
        request.predicate = NSPredicate(format: "listId == %@", listInfo.listId as CVarArg)
        guard let storedList = try? context.fetch(request).first else {
            return
        }
        storedList.listId = listInfo.listId
        storedList.title = listInfo.title
        storedList.date = listInfo.date
        storedList.completed = listInfo.completed
        storedList.pinned = listInfo.pinned
        delegate?.saveContext()
    }
    
    func deleteItemsFromList(list id: UUID) {
        let listItems = fetchItemsForList(with: id)
        for item in listItems {
            context.delete(item)
        }
        delegate?.saveContext()
    }
    
    func deleteListFromStore(with id: UUID) {
        if let fetchedList = fetchListCoreData(with: id) {
            context.delete(fetchedList)
        }
        delegate?.saveContext()
    }
    
    // MARK: - Private Methods
    private func buildListItemCoreData(from item: ListItem) -> ListItemCoreData {
        let coreDataItem = ListItemCoreData(context: context)
        coreDataItem.name = item.name
        coreDataItem.quantity = item.quantity
        coreDataItem.unit = item.unit
        coreDataItem.checked = item.checked
        return coreDataItem
    }
}
