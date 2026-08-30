import CoreData

final class CoreDataService {

    // MARK: - Private Properties
    private let context: NSManagedObjectContext

    // MARK: - Initializers
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Public Methods
    func addNewListToStore(list: ShopList) throws {
        try context.performAndWait {
            guard try fetchListCoreDataInContext(with: list.info.listId) == nil else {
                throw StorageServiceError.listAlreadyExists
            }

            let storedList = ShoppingListCoreData(context: context)
            apply(list.info, to: storedList)
            replaceItems(in: storedList, with: list.items)
            try saveContext()
        }
    }

    func deleteListFromStore(with id: UUID) throws {
        try context.performAndWait {
            guard let storedList = try fetchListCoreDataInContext(with: id) else {
                return
            }

            context.delete(storedList)
            try saveContext()
        }
    }

    func deleteListsFromStore(with ids: [UUID]) throws {
        guard !ids.isEmpty else {
            return
        }

        try context.performAndWait {
            let request = NSFetchRequest<ShoppingListCoreData>(entityName: "ShoppingListCoreData")
            request.predicate = NSPredicate(format: "listId IN %@", ids)
            try context.fetch(request).forEach { storedList in
                context.delete(storedList)
            }
            try saveContext()
        }
    }

    func fetchItemsForList(with id: UUID) throws -> [ListItem] {
        try context.performAndWait {
            let request = NSFetchRequest<ListItemCoreData>(entityName: "ListItemCoreData")
            request.predicate = NSPredicate(format: "shoppingList.listId == %@", id as CVarArg)
            request.sortDescriptors = [
                NSSortDescriptor(key: "sortIndex", ascending: true),
                NSSortDescriptor(key: "name", ascending: true)
            ]
            return try context.fetch(request).map(makeListItem)
        }
    }

    func fetchList(with id: UUID) throws -> ShopList? {
        try context.performAndWait {
            guard let storedList = try fetchListCoreDataInContext(with: id),
                  let listInfo = makeListInfo(from: storedList) else {
                return nil
            }

            let storedItems = (storedList.listItems as? Set<ListItemCoreData>) ?? []
            let items = storedItems.sorted {
                if $0.sortIndex != $1.sortIndex {
                    return $0.sortIndex < $1.sortIndex
                }
                return ($0.name ?? "") < ($1.name ?? "")
            }.map(makeListItem)
            return ShopList(info: listInfo, items: items)
        }
    }

    func fetchListsWith(status isCompleted: Bool) throws -> [ListInfo] {
        try context.performAndWait {
            let request = NSFetchRequest<ShoppingListCoreData>(entityName: "ShoppingListCoreData")
            request.predicate = NSPredicate(format: "completed == %@", NSNumber(value: isCompleted))
            request.sortDescriptors = [
                NSSortDescriptor(key: "pinned", ascending: false),
                NSSortDescriptor(key: "date", ascending: false)
            ]

            return try context.fetch(request).compactMap(makeListInfo)
        }
    }

    func restoreList(with id: UUID) throws {
        try context.performAndWait {
            guard let storedList = try fetchListCoreDataInContext(with: id) else {
                throw StorageServiceError.listNotFound
            }

            storedList.completed = false
            storedList.date = Date()
            storedList.pinned = false
            storedList.reminderDate = nil
            (storedList.listItems as? Set<ListItemCoreData>)?.forEach { $0.checked = false }
            try saveContext()
        }
    }

    func updateListInStore(list: ShopList) throws {
        try context.performAndWait {
            guard let storedList = try fetchListCoreDataInContext(with: list.info.listId) else {
                throw StorageServiceError.listNotFound
            }

            apply(list.info, to: storedList)
            replaceItems(in: storedList, with: list.items)
            try saveContext()
        }
    }

    func updateListInfoInStore(listInfo: ListInfo) throws {
        try context.performAndWait {
            guard let storedList = try fetchListCoreDataInContext(with: listInfo.listId) else {
                throw StorageServiceError.listNotFound
            }

            apply(listInfo, to: storedList)
            try saveContext()
        }
    }

    // MARK: - Private Methods
    private func apply(_ listInfo: ListInfo, to storedList: ShoppingListCoreData) {
        storedList.completed = listInfo.completed
        storedList.date = listInfo.date
        storedList.listId = listInfo.listId
        storedList.pinned = listInfo.pinned
        storedList.reminderDate = listInfo.reminderDate
        storedList.title = listInfo.title
    }

    private func fetchListCoreDataInContext(with id: UUID) throws -> ShoppingListCoreData? {
        let request = NSFetchRequest<ShoppingListCoreData>(entityName: "ShoppingListCoreData")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "listId == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private func makeListInfo(from storedList: ShoppingListCoreData) -> ListInfo? {
        guard let listId = storedList.listId,
              let date = storedList.date,
              let title = storedList.title else {
            return nil
        }

        return ListInfo(
            listId: listId,
            title: title,
            date: date,
            completed: storedList.completed,
            pinned: storedList.pinned,
            reminderDate: storedList.reminderDate
        )
    }

    private func makeListItem(from storedItem: ListItemCoreData) -> ListItem {
        ListItem(
            name: storedItem.name ?? "",
            quantity: storedItem.quantity,
            unit: storedItem.unit ?? Units.piece.rawValue,
            checked: storedItem.checked
        )
    }

    private func replaceItems(in storedList: ShoppingListCoreData, with items: [ListItem]) {
        (storedList.listItems as? Set<ListItemCoreData>)?.forEach(context.delete)

        items.enumerated().forEach { index, item in
            let storedItem = ListItemCoreData(context: context)
            storedItem.checked = item.checked
            storedItem.name = item.name
            storedItem.quantity = item.quantity
            storedItem.sortIndex = Int64(index)
            storedItem.unit = item.unit
            storedItem.shoppingList = storedList
        }
    }

    private func saveContext() throws {
        guard context.hasChanges else {
            return
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
