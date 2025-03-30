import Foundation

protocol ShoppingListViewModelProtocol {
    var shoppingListBinding: Observable<ShoppingListBinding> { get set }
    
    func viewWillAppear()
    func listIsCompleted() -> Bool
    func checkAllSwitchIs(on: Bool)
    func getBottomButtonName() -> String
    func rowMoved(from: Int, to: Int)
    func sortButtonPressed()
    func doneButtonPressed()
    func getListTitle() -> String
    func getTableRowCount() -> Int
    func getRowHeight(for row: Int) -> CGFloat
    func getCellParams(for row: Int) -> (ShopListCellType, ShopListCellParams)
    func isDropAllowed(for row: Int) -> Bool
    func tableFinishedUpdating()
    func deleteItemButtonPressed(in row: Int)
}

final class ShoppingListViewModel: ShoppingListViewModelProtocol {
    // MARK: - Public Properties
    var shoppingListBinding: Observable<ShoppingListBinding> = Observable(nil)
    
    // MARK: - Private Properties
    private let coordinator: Coordinator
    private let storageService: StorageServiceProtocol
    private var currentListInfo: ListInfo
    private var shoppingList: [ShopListCellParams] = []
    private var uncheckedItemsCount: Int = 0
    private var sortOrderAscending : Bool?
    private var userIsTyping: Bool = false
    private var bottomButtonIsEnabled: Bool = false
    
    //MARK: - Initializers
    init(coordinator: Coordinator, listInfo: ListInfo) {
        self.currentListInfo = listInfo
        self.coordinator = coordinator
        self.storageService = coordinator.storageService
    }
    
    // MARK: - Public Methods
    func viewWillAppear() {
        loadList()
        updateBottomButtonState()
    }
    
    func getListTitle() -> String {
        currentListInfo.title
    }
    
    func listIsCompleted() -> Bool {
        currentListInfo.completed
    }
    
    func getBottomButtonName() -> String {
        currentListInfo.completed ? .buttonRestoreList : .buttonRemoveCheckedItems
    }
    
    func getTableRowCount() -> Int {
        shoppingList.count
    }
    
    func getRowHeight(for row: Int) -> CGFloat {
        switch row {
            
        case shoppingList.count - 1:
            52
            
        default:
            shoppingList[row].error == nil ? 52 : 81
        }
    }
    
    func getCellParams(for row: Int) -> (ShopListCellType, ShopListCellParams) {
        return (row == shoppingList.count - 1 ? .button : .item,
                .init(checked: shoppingList[row].checked,
                      title: shoppingList[row].title,
                      quantity: shoppingList[row].quantity,
                      unit: shoppingList[row].unit,
                      error: shoppingList[row].error
                     )
        )
    }
    
    func isDropAllowed(for row: Int) -> Bool {
        row < uncheckedItemsCount
    }
    
    func tableFinishedUpdating() {
        saveListToStorage(duplicatePinned: false)
        userIsTyping = false
    }
    
    // MARK: - Actions
    func sortButtonPressed() {
        var uncheckedItems = [ShopListCellParams]()
        var checkedItems = [ShopListCellParams]()
        var indexesToUpdate: [IndexPath] = []
        
        for (index, item) in shoppingList[0...shoppingList.count - 2].enumerated() {
            item.checked
            ? checkedItems.append(item)
            : uncheckedItems.append(item)
            
            indexesToUpdate.append(.init(row: index, section: 0))
        }
        
        if sortOrderAscending == true {
            shoppingList = uncheckedItems.sorted{$0.title ?? "" > $1.title ?? ""}
            sortOrderAscending?.toggle()
        } else {
            shoppingList = uncheckedItems.sorted{$0.title ?? "" < $1.title ?? ""}
            sortOrderAscending = true
        }
        
        shoppingList += checkedItems
        
        shoppingList.append(.init(checked: true,
                                  title: .buttonAddProduct,
                                  quantity: 1,
                                  unit: .piece)
        )
        
        shoppingListBinding.value = .updateItem(indexesToUpdate, true)
    }
    
    func checkAllSwitchIs(on: Bool) {
        let lastRow = shoppingList.count - 2
        guard lastRow >= 0 else {
            return
        }
        var indexesToUpdate: [IndexPath] = []
        for index in 0...shoppingList.count - 2 {
            
            switch on {
                
            case true:
                if !shoppingList[index].checked {
                    shoppingList[index].checked = true
                    indexesToUpdate.append(.init(row: index, section: 0))
                    uncheckedItemsCount -= 1
                }
                
            case false:
                if shoppingList[index].checked {
                    shoppingList[index].checked = false
                    indexesToUpdate.append(.init(row: index, section: 0))
                    uncheckedItemsCount += 1
                }
            }
        }
        
        if indexesToUpdate.isEmpty {
            return
        }
        shoppingListBinding.value = .updateItem(indexesToUpdate, true)
    }
    
    func rowMoved(from sourceIndex: Int, to destinationIndex: Int) {
        moveItemInArray(from: sourceIndex, to: destinationIndex)
        tableFinishedUpdating()
    }
    
    func doneButtonPressed() {
        switch currentListInfo.completed {
            
        case true: // если смотрим завершенный список (проверить, есть ли активный закреп с таким названием)
            storageService.restoreList(with: currentListInfo.listId)
            coordinator.popToMainView()
            
        case false: // если завершаем актив. список
            coordinator.showSuccessView(delegate: self)
        }
    }
    
    func deleteItemButtonPressed(in row: Int) {
        if !shoppingList[row].checked {
            uncheckedItemsCount -= 1
        }
        shoppingList.remove(at: row)
        shoppingListBinding.value = .removeItem(.init(row: row, section: 0))
    }
    
    // MARK: - Private Methods
    private func loadList() {
        guard let loadedItems = storageService.getItems(by: currentListInfo.listId) else {
            return
        }
        loadedItems.enumerated().forEach {index, item in
            shoppingList.append(.init(checked: item.checked,
                                      title: item.name,
                                      quantity: Float(item.quantity),
                                      unit: Units(rawValue: item.unit) ?? .piece
                                     )
            )
            if !item.checked {
                uncheckedItemsCount += 1
            }
        }
        shoppingList.append(.init(checked: true,
                                  title: .buttonAddProduct,
                                  quantity: 1,
                                  unit: .piece)
        )
    }
    
    private func moveItemInArray(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex else { return }
        let place = shoppingList[sourceIndex]
        shoppingList.remove(at: sourceIndex)
        shoppingList.insert(place, at: destinationIndex)
    }
    
    @discardableResult
    private func validateName(row: Int) -> Bool { // возвращает true если статус изменился
        guard let newTitle = shoppingList[row].title else {
            return false
        }
        
        let oldErrorStatus = shoppingList[row].error
        
        if newTitle.isEmpty {
            shoppingList[row].error = .newListEmptyName
            
        } else if newTitle.replacingOccurrences(of: " ", with: "").isEmpty {
            shoppingList[row].error = .newListWrongName
            
        } else {
            shoppingList[row].error = nil
        }
        
        return oldErrorStatus != shoppingList[row].error
    }
    
    private func updateBottomButtonState() {
        let newState = currentListInfo.completed
        ? true
        : shoppingList.first(where: { $0.checked == false}) == nil
        
        if bottomButtonIsEnabled != newState {
            bottomButtonIsEnabled.toggle()
        }
    }
    
    private func validateList() -> Bool {
        shoppingList.first(where: { $0.title == nil || $0.title?.isEmpty == true || $0.error != nil}) == nil
    }
    
    private func saveListToStorage(duplicatePinned: Bool) {
        var newListItems = [ListItem]()
        if shoppingList.count > 1 {
            for item in shoppingList[0...shoppingList.count - 2] {
                newListItems.append(.init(name: item.title ?? "",
                                          quantity: Float(item.quantity),
                                          unit: item.unit.rawValue,
                                          checked: item.checked
                                         )
                )
            }
        }
        
        let list = ShopList(
            info: .init(listId: duplicatePinned ? UUID() : currentListInfo.listId,
                        title: currentListInfo.title,
                        date: duplicatePinned ? Date() : currentListInfo.date,
                        completed: duplicatePinned ? true : currentListInfo.completed,
                        pinned: duplicatePinned ? false : currentListInfo.pinned
                       ),
            items: newListItems
        )
        
        duplicatePinned
        ? storageService.saveNewList(list: list)
        : storageService.updateList(list: list)
    }
}

// MARK: - ShoppingListCellItemDelegate
extension ShoppingListViewModel: ShoppingListCellDelegate {
    func updateShoppingListItem(in row: Int, with title: String) {
        
        let oldTitle = shoppingList[row].title
        shoppingList[row].title = title
        
        if validateName(row: row) {
            shoppingListBinding.value = .updateItem([.init(row: row, section: 0)], true)
            
        } else {
            if oldTitle != title {
                saveListToStorage(duplicatePinned: false)
            }
            userIsTyping = false
        }
    }
    
    func getTextFieldEditState() -> Bool {
        return userIsTyping
    }
    
    func textFieldDidBeginEditing() {
        userIsTyping = true
    }
    
    func editQuantityButtonPressed(in row: Int) {
        if userIsTyping {
            return
        }
        
        shoppingListBinding.value = .showPopUp(row, shoppingList[row].quantity, shoppingList[row].unit)
    }
    
    func checkBoxTapped(in row: Int) {
        if currentListInfo.completed || userIsTyping {
            return
        }
        let wasChecked = shoppingList[row].checked
        shoppingList[row].checked.toggle()
        
        if wasChecked {// cмена с отмеченного на неотмеченный
            if row > uncheckedItemsCount {
                moveItemInArray(from: row, to: uncheckedItemsCount)
                shoppingListBinding.value = .moveItem(.init(row: row, section: 0),
                                                      .init(row: uncheckedItemsCount, section: 0)
                )
                
            } else {
                shoppingListBinding.value = .updateItem([.init(row: row, section: 0)], true)
            }
            uncheckedItemsCount += 1
            
        } else {// смена с неотмеченного на отмеченный
            if row == uncheckedItemsCount - 1 {
                shoppingListBinding.value = .updateItem([.init(row: row, section: 0)], true)
            } else {
                moveItemInArray(from: row, to: uncheckedItemsCount - 1)
                shoppingListBinding.value = .moveItem(.init(row: row, section: 0),
                                                      .init(row: uncheckedItemsCount-1, section: 0)
                )
            }
            uncheckedItemsCount -= 1
        }
    }
    
    func addNewItemButtonPressed() {
        if userIsTyping || !validateList() {
            return
        }
        shoppingList.insert(.init(checked: false,
                                  quantity: 1,
                                  unit: .piece,
                                  error: .newListEmptyName
                                 ),
                            at: uncheckedItemsCount
        )
        uncheckedItemsCount += 1
        shoppingListBinding.value = .insertItem(.init(row: uncheckedItemsCount - 1, section: 0))
    }
}

// MARK: - PopUpVCDelegate
extension ShoppingListViewModel: PopUpVCDelegate {
    func unitSelected(item: Int, unit: Units) {
        shoppingList[item].unit = unit
        shoppingListBinding.value = .updateItem([.init(row: item, section: 0)], false)
    }
    
    func quantitySelected(item: Int, quantity: Float) {
        shoppingList[item].quantity = quantity
        shoppingListBinding.value = .updateItem([.init(row: item, section: 0)], false)
    }
}

// MARK: - PopUpVCDelegate
extension ShoppingListViewModel: SuccessViewDelegate {
    func confirmButtonPressed() {
        if currentListInfo.pinned {
            saveListToStorage(duplicatePinned: true)
            if shoppingList.count > 1 {
                for index in 0...shoppingList.count - 2 {
                    shoppingList[index].checked = false
                }
            }
            
        } else {
            currentListInfo.setCompleted(to: true)
        }
        saveListToStorage(duplicatePinned: false)
        coordinator.dismissPopupVC()
        coordinator.switchToMainView()
    }
    
    func cancelButtonPressed() {
        coordinator.dismissPopupVC()
    }
}
