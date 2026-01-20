import Foundation
import EventKit
import UserNotifications

protocol ShoppingListViewModelProtocol {
    var shoppingListBinding: Observable<ShoppingListBinding> { get set }
    var notificationText: String { get }
    
    func viewDidLoad()
    func viewWillAppear()
    func listIsCompleted() -> Bool
    func checkAllSwitchIs(on: Bool)
    func getBottomButtonName() -> String
    func rowMoved(from: Int, to: Int)
    func sortButtonPressed()
    func duplicateButtonPressed()
    func doneButtonPressed()
    func getListTitle() -> String
    func getTableRowCount() -> Int
    func getRowHeight(for row: Int) -> CGFloat
    func getCellParams(for row: Int) -> (ShopListCellType, ShopListCellParams)
    func isDropAllowed(for row: Int) -> Bool
    func tableFinishedUpdating()
    func deleteItemButtonPressed(in row: Int)
    func addNoticeButtonPressed()
    func addEventAndNotification(date: Date)
}

final class ShoppingListViewModel: ShoppingListViewModelProtocol {
    // MARK: - Public Properties
    var shoppingListBinding: Observable<ShoppingListBinding> = Observable(nil)
    
    // MARK: - Private Properties
    lazy var notificationText: String = {
        "\(String.notificationText) '\(currentListInfo.title)'"
    }()
    
    private let coordinator: Coordinator
    private let storageService: StorageServiceProtocol
    private let eventStore = EKEventStore()
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
    func viewDidLoad() {
        requestCalendarAccess()
        requestNotificationAuthorization()
    }
    
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
            currentListInfo.completed || shoppingList[row].error == nil ? 52 : 81
            
        default:
            shoppingList[row].error == nil ? 52 : 81
        }
    }
    
    func getCellParams(for row: Int) -> (ShopListCellType, ShopListCellParams) {
        return (row == shoppingList.count - 1 && !currentListInfo.completed ? .button : .item,
                .init(id: shoppingList[row].id,
                      checked: shoppingList[row].checked,
                      title: shoppingList[row].title,
                      quantity: shoppingList[row].quantity,
                      unit: shoppingList[row].unit,
                      error: shoppingList[row].error
                     )
        )
    }
    
    func isDropAllowed(for row: Int) -> Bool {
        row < uncheckedItemsCount && !currentListInfo.completed
    }
    
    func tableFinishedUpdating() {
        saveListToStorage(duplicatePinned: false)
        userIsTyping = false
    }
    
    func addEventAndNotification(date: Date) {
        
        guard date > Date() else {
            return
        }
        
        coordinator.dismissPopupVC()
        
        let event = EKEvent(eventStore: eventStore)
        event.title = .appName
        event.notes = notificationText
        event.startDate = date
        event.endDate = date.addingTimeInterval(3600)
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("Событие сохранено в календаре")
        } catch {
            print("Ошибка сохранения события: \(error.localizedDescription)")
        }
        
        let content = UNMutableNotificationContent()
        content.title = .appName
        content.body = notificationText
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "event_\(event.eventIdentifier ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка уведомления: \(error.localizedDescription)")
            } else {
                print("Уведомление создано")
            }
        }
    }
    
    // MARK: - Actions
    func sortButtonPressed() {
        guard uncheckedItemsCount > 0 else { return }
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
        
        if !currentListInfo.completed {
            shoppingList.append(.init(id: UUID(),
                                      checked: true,
                                      title: .buttonAddProduct,
                                      quantity: 1,
                                      unit: .piece)
            )
        }
        
        shoppingListBinding.value = .updateItem(indexesToUpdate, true)
    }
    
    func duplicateButtonPressed() {
        duplicateList()
    }
    
    func addNoticeButtonPressed() {
        coordinator.showDatePickerView(delegate: self)
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
            shoppingList.append(.init(id: UUID(),
                                      checked: item.checked,
                                      title: item.name,
                                      quantity: Float(item.quantity),
                                      unit: Units(rawValue: item.unit) ?? .piece
                                     )
            )
            if !item.checked {
                uncheckedItemsCount += 1
            }
        }
        if !currentListInfo.completed{
            shoppingList.append(.init(id: UUID(),
                                      checked: true,
                                      title: .buttonAddProduct,
                                      quantity: 1,
                                      unit: .piece)
            )
        }
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
    
    private func duplicateList() {
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
            info: .init(listId: UUID(),
                        title: "\(currentListInfo.title)#",
                        date: Date(),
                        completed: false,
                        pinned: false
                       ),
            items: newListItems
        )
        storageService.saveNewList(list: list)
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
    
    // Запрос доступа к календарю
    private func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { granted, error in
            if granted {
                print("Доступ к календарю разрешен")
            } else if let error = error {
                print("Ошибка доступа к календарю: \(error.localizedDescription)")
            }
        }
    }
    
    // Запрос разрешения на уведомления
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Уведомления разрешены")
            } else if let error = error {
                print("Ошибка уведомлений: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - ShoppingListCellItemDelegate
extension ShoppingListViewModel: ShoppingListCellDelegate {
    
    func updateShoppingListItem(cellID: UUID, with title: String) {
        let cellRow = getItemRowBy(id: cellID)
        let oldTitle = shoppingList[cellRow].title
        shoppingList[cellRow].title = title
        
        if validateName(row: cellRow) {
            shoppingListBinding.value = .updateItem([.init(row: cellRow, section: 0)], true)
            
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
    
    func editQuantityButtonPressed(cellID: UUID) {
        if userIsTyping {
            return
        }
        
        let row = getItemRowBy(id: cellID)
        shoppingListBinding.value = .showPopUp(cellID, shoppingList[row].quantity, shoppingList[row].unit)
    }
    
    func checkBoxTapped(cellID: UUID) {
        if currentListInfo.completed || userIsTyping {
            return
        }
        let row = getItemRowBy(id: cellID)
        
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
        shoppingList.insert(.init(id: UUID(),
                                  checked: false,
                                  quantity: 1,
                                  unit: .piece,
                                  error: .newListEmptyName
                                 ),
                            at: uncheckedItemsCount
        )
        uncheckedItemsCount += 1
        shoppingListBinding.value = .insertItem(.init(row: uncheckedItemsCount - 1, section: 0))
    }
    
    private func getItemRowBy(id: UUID) -> Int {
        shoppingList.firstIndex(where: { $0.id == id }) ?? 0
    }
}

// MARK: - PopUpVCDelegate
extension ShoppingListViewModel: PopUpVCDelegate {
    func unitSelected(itemID: UUID, unit: Units) {
        shoppingList[getItemRowBy(id: itemID)].unit = unit
        shoppingListBinding.value = .updateItem([.init(row: getItemRowBy(id: itemID), section: 0)], false)
    }
    
    func quantitySelected(itemID: UUID, quantity: Float) {
        shoppingList[getItemRowBy(id: itemID)].quantity = quantity
        shoppingListBinding.value = .updateItem([.init(row: getItemRowBy(id: itemID), section: 0)], false)
    }
}

// MARK: - SuccessViewDelegate
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

// MARK: - DatePickerViewDelegate
extension ShoppingListViewModel: DatePickerViewDelegate {
    func datePickerConfirmButtonPressed(date: Date) {
        addEventAndNotification(date: date)
    }
    
    func datePickerCancelButtonPressed() {
        coordinator.dismissPopupVC()
    }
}
