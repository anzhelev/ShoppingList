import Foundation

protocol ShoppingListViewModelProtocol {
    var needToUpdateBottomButtonState: Observable<Bool> { get set }
    var userInteractionEnabled: Observable<Bool> { get set }
    var switchToSuccessView: Observable<String> { get set }
    var switchToMainView: Observable<Bool> { get set }
    var needToClosePopUp: Observable<Bool> { get set }
    var popUpQuantity: Observable<Int> { get set }
    var popUpUnit: Observable<Int> { get set }
    var needToShowPopUp: Observable<Int> { get set }
    var needToUpdateItem: Observable<([IndexPath],Bool)> { get set }
    var needToInsertItem: Observable<IndexPath> { get set }
    var needToMoveItem: Observable<(IndexPath,IndexPath)> { get set }
    var needToRemoveItem: Observable<IndexPath> { get set }
    func viewWillAppear()
    func listIsCompleted() -> Bool
    func checkAllSwitchIs(on: Bool)
    func getBottomButtonName() -> String
    func rowMoved(from: Int, to: Int)
    func sortButtonPressed()
    func bottomButtonPressed()
    func getListTitle() -> String
    func getTableRowCount() -> Int
    func getRowHeight(for row: Int) -> CGFloat
    func getCellParams(for row: Int) -> (ShopListCellType, ShopListCellParams)
    func tableFinishedUpdating()
    func deleteItemButtonPressed(in row: Int)
    func textFieldDidBeginEditing()
}

final class ShoppingListViewModel: ShoppingListViewModelProtocol {
    // MARK: - Public Properties
    var userInteractionEnabled: Observable<Bool> = Observable(true)
    var switchToSuccessView: Observable<String> = Observable(nil)
    var switchToMainView: Observable<Bool> = Observable(nil)
    var needToUpdateBottomButtonState: Observable<Bool> = Observable(false)
    var needToClosePopUp: Observable<Bool> = Observable(false)
    var popUpQuantity: Observable<Int> = Observable(nil)
    var popUpUnit: Observable<Int> = Observable(nil)
    var needToShowPopUp: Observable<Int> = Observable(nil)
    var needToUpdateItem: Observable<([IndexPath],Bool)> = Observable(nil)
    var needToInsertItem: Observable<IndexPath> = Observable(nil)
    var needToMoveItem: Observable<(IndexPath,IndexPath)> = Observable(nil)
    var needToRemoveItem: Observable<IndexPath> = Observable(nil)
    
    // MARK: - Private Properties
    private let storageService: StorageServiceProtocol
    private var currentListInfo: ListInfo
    private var shoppingList: [ShopListCellParams] = []
    private var uncheckedItemsCount: Int = 0
    private var sortOrderAscending : Bool?
    private var checkBoxesAreBlocked: Bool = false
    
    //MARK: - Initializers
    init(listInfo: ListInfo, storageService: StorageServiceProtocol) {
        self.currentListInfo = listInfo
        self.storageService = storageService
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
    
    func tableFinishedUpdating() {
        userInteractionEnabled.value = true
        saveListToStorage(duplicatePinned: false)
        updateBottomButtonState()
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
            
            indexesToUpdate.append(IndexPath(row: index, section: 0))
        }
        
        if sortOrderAscending == true {
            shoppingList = uncheckedItems.sorted{$0.title > $1.title}
            sortOrderAscending?.toggle()
        } else {
            shoppingList = uncheckedItems.sorted{$0.title < $1.title}
            sortOrderAscending = true
        }
        
        shoppingList += checkedItems
        
        shoppingList.append(.init(checked: true,
                                  title: .buttonAddProduct,
                                  quantity: 1,
                                  unit: .piece)
        )
        
        userInteractionEnabled.value = false
        needToUpdateItem.value = (indexesToUpdate, true)
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
                    indexesToUpdate.append(IndexPath(row: index, section: 0))
                    uncheckedItemsCount -= 1
                }
                
            case false:
                if shoppingList[index].checked {
                    shoppingList[index].checked = false
                    indexesToUpdate.append(IndexPath(row: index, section: 0))
                    uncheckedItemsCount += 1
                }
            }
        }
        
        if indexesToUpdate.isEmpty {
            return
        }
        userInteractionEnabled.value = false
        needToUpdateItem.value = (indexesToUpdate, true)
    }
    
    func rowMoved(from sourceIndex: Int, to destinationIndex: Int) {
        moveItemInArray(from: sourceIndex, to: destinationIndex)
    }
    
    func bottomButtonPressed() {
        switch currentListInfo.completed {
            
        case true: // если смотрим завершенный список (проверить, есть ли активный закреп с таким названием)
            storageService.restoreList(with: currentListInfo.listId)
            switchToMainView.value = true
            
        case false: // если завершаем актив. список
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
            
            switchToSuccessView.value = currentListInfo.title
        }
    }
    
    func deleteItemButtonPressed(in row: Int) {
        if !shoppingList[row].checked {
            uncheckedItemsCount -= 1
        }
        shoppingList.remove(at: row)
        userInteractionEnabled.value = false
        needToRemoveItem.value = IndexPath(row: row, section: 0)
    }
    
    // MARK: - Private Methods
    private func loadList() {
        guard let loadedItems = storageService.getItems(by: currentListInfo.listId) else {
            return
        }
        loadedItems.enumerated().forEach {index, item in
            shoppingList.append(.init(checked: item.checked,
                                      title: item.name,
                                      quantity: Int(item.quantity),
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
    
    private func validateName(row: Int) {
        if shoppingList[row].title.isEmpty {
            shoppingList[row].title = .newListItemPlaceholder
            shoppingList[row].error = .newListEmptyName
            return
        } else if shoppingList[row].title.replacingOccurrences(of: " ", with: "").isEmpty {
            shoppingList[row].title = .newListItemPlaceholder
            shoppingList[row].error = .newListWrongName
            return
        }
        shoppingList[row].error = nil
    }
    
    private func updateBottomButtonState() {
        let newState = currentListInfo.completed
        ? true
        : shoppingList.first(where: { $0.checked == false}) == nil
        
        if needToUpdateBottomButtonState.value != newState {
            needToUpdateBottomButtonState.value?.toggle()
        }
    }
    
    private func saveListToStorage(duplicatePinned: Bool) {
        var newListItems = [ListItem]()
        if shoppingList.count > 1 {
            for item in shoppingList[0...shoppingList.count - 2] {
                newListItems.append(.init(name: item.title,
                                          quantity: Int16(item.quantity),
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
extension ShoppingListViewModel: ShoppingListCellItemDelegate {
    func updateShoppingListItem(in row: Int, with title: String, quantity: Int, unit: Units) {
        checkBoxesAreBlocked = false
        let oldItemState = shoppingList[row]
        shoppingList[row].title = title
        shoppingList[row].quantity = quantity
        shoppingList[row].unit = unit
        validateName(row: row)
        if shoppingList[row].error != oldItemState.error {
            userInteractionEnabled.value = false
            needToUpdateItem.value = ([IndexPath(row: row, section: 0)], true)
        }
        guard oldItemState.title == shoppingList[row].title,
              oldItemState.quantity == shoppingList[row].quantity,
              oldItemState.unit == shoppingList[row].unit
        else {
            saveListToStorage(duplicatePinned: false)
            return
        }
    }
    
    func textFieldDidBeginEditing() {
        checkBoxesAreBlocked = true
    }
    
    func editQuantityButtonPressed(in row: Int) {
        if checkBoxesAreBlocked {
            return
        }
        needToShowPopUp.value = row
    }
    
    func checkBoxTapped(in row: Int) {
        if currentListInfo.completed || checkBoxesAreBlocked {
            return
        }
        let wasChecked = shoppingList[row].checked
        shoppingList[row].checked.toggle()
        userInteractionEnabled.value = false
        
        if wasChecked {// cмена с отмеченного на неотмеченный
            if row > uncheckedItemsCount {
                moveItemInArray(from: row, to: uncheckedItemsCount)
                needToMoveItem.value = (IndexPath(row: row, section: 0),
                                        IndexPath(row: uncheckedItemsCount, section: 0)
                )
                
            } else {
                needToUpdateItem.value = ([IndexPath(row: row, section: 0)], true)
            }
            uncheckedItemsCount += 1
            
        } else {// смена с неотмеченного на отмеченный
            if row == uncheckedItemsCount - 1 {
                needToUpdateItem.value = ([IndexPath(row: row, section: 0)], true)
                
            } else {
                moveItemInArray(from: row, to: uncheckedItemsCount - 1)
                needToMoveItem.value = (IndexPath(row: row, section: 0),
                                        IndexPath(row: uncheckedItemsCount-1, section: 0)
                )
            }
            uncheckedItemsCount -= 1
        }
    }
}

// MARK: - ShoppingListCellButtonDelegate
extension ShoppingListViewModel: ShoppingListCellButtonDelegate {
    func addNewItemButtonPressed() {
        if checkBoxesAreBlocked {
            return
        }
        shoppingList.insert(.init(checked: false,
                                  title: .newListItemPlaceholder,
                                  quantity: 1,
                                  unit: .piece
                                 ), at: uncheckedItemsCount
        )
        uncheckedItemsCount += 1
        userInteractionEnabled.value = false
        needToInsertItem.value = IndexPath(row: uncheckedItemsCount - 1, section: 0)
    }
}

// MARK: - PopUpVCDelegate
extension ShoppingListViewModel: PopUpVCDelegate {
    
    func popUpView(for item: Int, isShowing : Bool) {
        if isShowing {
            popUpQuantity.value = shoppingList[item].quantity
            
            switch shoppingList[item].unit {
            case .kg:
                popUpUnit.value = 0
            case .liter:
                popUpUnit.value = 1
            case .pack:
                popUpUnit.value = 2
            case .piece:
                popUpUnit.value = 3
            }
        }
        userInteractionEnabled.value = !isShowing
    }
    
    func unitSelected(item: Int, unit index: Int) {
        var selectedUnit: Units
        
        switch index {
        case 0:
            selectedUnit = .kg
        case 1:
            selectedUnit = .liter
        case 2:
            selectedUnit = .pack
        default:
            selectedUnit = .piece
        }
        
        if shoppingList[item].unit != selectedUnit {
            shoppingList[item].unit = selectedUnit
        }
        needToUpdateItem.value = ([IndexPath(row: item, section: 0)], false)
    }
    
    func minusButtonPressed(item: Int) {
        let quantity = shoppingList[item].quantity
        if shoppingList[item].quantity != max(quantity - 1, 1) {
            shoppingList[item].quantity = max(quantity - 1, 1)
            needToUpdateItem.value = ([IndexPath(row: item, section: 0)], false)
            popUpQuantity.value = shoppingList[item].quantity
        }
    }
    
    func plusButtonPressed(item: Int) {
        let quantity = shoppingList[item].quantity
        if shoppingList[item].quantity != max(quantity + 1, 99) {
            shoppingList[item].quantity = min(quantity + 1, 99)
            needToUpdateItem.value = ([IndexPath(row: item, section: 0)], false)
            popUpQuantity.value = shoppingList[item].quantity
        }
    }
    
    func doneButtonPressed() {
        needToClosePopUp.value = true
    }
}
