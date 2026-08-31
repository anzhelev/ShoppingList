import Foundation

protocol ShoppingListViewModelProtocol: AnyObject {
    var shoppingListBinding: Observable<ShoppingListBinding> { get set }

    func addNoticeButtonPressed()
    func checkAllSwitchIs(on: Bool)
    func deleteItemButtonPressed(in row: Int)
    func doneButtonPressed()
    func duplicateButtonPressed()
    func getBottomButtonName() -> String
    func getBottomButtonState() -> Bool
    func getCellParams(for row: Int) -> (ShopListCellType, ShopListCellParams)
    func getCheckAllSwitchAvailability() -> Bool
    func getCheckAllSwitchState() -> Bool
    func getListTitle() -> String
    func getRowHeight(for row: Int) -> CGFloat
    func getTableRowCount() -> Int
    func isDropAllowed(for row: Int) -> Bool
    func listIsCompleted() -> Bool
    func rowMoved(from: Int, to: Int)
    func sortButtonPressed()
    func tableFinishedUpdating()
    func viewWillAppear()
}

final class ShoppingListViewModel: ShoppingListViewModelProtocol {

    // MARK: - Public Properties
    var shoppingListBinding: Observable<ShoppingListBinding> = Observable(nil)

    // MARK: - Private Properties
    private let coordinator: Coordinator
    private let notificationService: NotificationServiceProtocol
    private let storageService: StorageServiceProtocol
    private var currentListInfo: ListInfo
    private var shoppingList: [ShopListCellParams] = []
    private var sortOrderAscending = true
    private var uncheckedItemsCount = 0
    private var userIsTyping = false

    private var productCount: Int {
        currentListInfo.completed ? shoppingList.count : max(0, shoppingList.count - 1)
    }

    // MARK: - Initializers
    init(coordinator: Coordinator, listInfo: ListInfo) {
        self.coordinator = coordinator
        self.currentListInfo = listInfo
        notificationService = coordinator.notificationService
        storageService = coordinator.storageService
    }

    // MARK: - Public Methods
    func addNoticeButtonPressed() {
        coordinator.showDatePickerView(delegate: self)
    }

    func checkAllSwitchIs(on: Bool) {
        guard getCheckAllSwitchAvailability() else {
            return
        }

        let indexes = (0..<productCount).compactMap { index -> IndexPath? in
            guard shoppingList[index].checked != on else {
                return nil
            }

            shoppingList[index].checked = on
            return IndexPath(row: index, section: 0)
        }

        guard !indexes.isEmpty else {
            return
        }

        uncheckedItemsCount = on ? 0 : productCount
        publishControlsState()
        shoppingListBinding.value = .updateItems(indexes, true)
    }

    func deleteItemButtonPressed(in row: Int) {
        guard !currentListInfo.completed, row >= 0, row < productCount else {
            return
        }

        if !shoppingList[row].checked {
            uncheckedItemsCount -= 1
        }
        shoppingList.remove(at: row)
        publishControlsState()
        shoppingListBinding.value = .removeItem(IndexPath(row: row, section: 0))
    }

    func doneButtonPressed() {
        guard getBottomButtonState() else {
            return
        }

        if currentListInfo.completed {
            restoreList()
        } else {
            coordinator.showSuccessView(delegate: self)
        }
    }

    func duplicateButtonPressed() {
        do {
            let existingNames = try storageService.getExistingListNames(excluding: nil)
            let title = makeUniqueDuplicateTitle(existingNames: existingNames)
            let duplicate = ShopList(
                info: ListInfo(
                    listId: UUID(),
                    title: title,
                    date: Date(),
                    completed: false,
                    pinned: false
                ),
                items: makeListItems()
            )
            try storageService.saveNewList(list: duplicate)
            coordinator.showAlert(title: .appName, message: .listDuplicatedMessage)
        } catch {
            show(error)
        }
    }

    func getBottomButtonName() -> String {
        currentListInfo.completed ? .buttonRestoreList : .buttonRemoveCheckedItems
    }

    func getBottomButtonState() -> Bool {
        currentListInfo.completed || (productCount > 0 && uncheckedItemsCount == 0)
    }

    func getCellParams(for row: Int) -> (ShopListCellType, ShopListCellParams) {
        let isButton = !currentListInfo.completed && row == shoppingList.count - 1
        let item = shoppingList[row]
        return (
            isButton ? .button : .item,
            ShopListCellParams(
                id: item.id,
                checked: item.checked,
                title: item.title,
                quantity: item.quantity,
                unit: item.unit,
                error: item.error,
                isEditable: !currentListInfo.completed,
                startEditing: item.startEditing
            )
        )
    }

    func getCheckAllSwitchAvailability() -> Bool {
        !currentListInfo.completed
            && !userIsTyping
            && productCount > 0
            && shoppingList.prefix(productCount).allSatisfy { $0.error == nil }
    }

    func getCheckAllSwitchState() -> Bool {
        productCount > 0 && uncheckedItemsCount == 0
    }

    func getListTitle() -> String {
        currentListInfo.title
    }

    func getRowHeight(for row: Int) -> CGFloat {
        shoppingList[row].error == nil ? 52 : 81
    }

    func getTableRowCount() -> Int {
        shoppingList.count
    }

    func isDropAllowed(for row: Int) -> Bool {
        !currentListInfo.completed && !userIsTyping && row >= 0 && row < uncheckedItemsCount
    }

    func listIsCompleted() -> Bool {
        currentListInfo.completed
    }

    func rowMoved(from sourceIndex: Int, to destinationIndex: Int) {
        guard isDropAllowed(for: sourceIndex), isDropAllowed(for: destinationIndex) else {
            return
        }

        moveItemInArray(from: sourceIndex, to: destinationIndex)
        saveListToStorage()
    }

    func sortButtonPressed() {
        guard !currentListInfo.completed, productCount > 1 else {
            return
        }

        let products = Array(shoppingList.prefix(productCount))
        let unchecked = products.filter { !$0.checked }.sorted(by: compareItems)
        let checked = products.filter(\.checked).sorted(by: compareItems)
        let button = shoppingList.last
        shoppingList = unchecked + checked
        if let button {
            shoppingList.append(button)
        }
        sortOrderAscending.toggle()
        saveListToStorage()
        shoppingListBinding.value = .reloadTable
    }

    func tableFinishedUpdating() {
        saveListToStorage()
        publishControlsState()
    }

    func viewWillAppear() {
        loadList()
    }

    // MARK: - Private Methods
    private func compareItems(_ first: ShopListCellParams, _ second: ShopListCellParams) -> Bool {
        let comparison = (first.title ?? "").localizedCaseInsensitiveCompare(second.title ?? "")
        return sortOrderAscending ? comparison == .orderedAscending : comparison == .orderedDescending
    }

    private func getItemRow(by id: UUID) -> Int? {
        shoppingList.firstIndex { item in
            item.id == id && (currentListInfo.completed || item.id != shoppingList.last?.id)
        }
    }

    private func loadList() {
        do {
            userIsTyping = false
            let items = try storageService.getItems(by: currentListInfo.listId)
            let mappedItems = items.map {
                ShopListCellParams(
                    id: UUID(),
                    checked: $0.checked,
                    title: $0.name,
                    quantity: $0.quantity,
                    unit: Units(rawValue: $0.unit) ?? .piece,
                    error: nil,
                    isEditable: !currentListInfo.completed,
                    startEditing: false
                )
            }
            let unchecked = mappedItems.filter { !$0.checked }
            let checked = mappedItems.filter(\.checked)
            shoppingList = unchecked + checked
            uncheckedItemsCount = unchecked.count

            if !currentListInfo.completed {
                shoppingList.append(
                    ShopListCellParams(
                        id: UUID(),
                        checked: true,
                        title: .buttonAddProduct,
                        quantity: 1,
                        unit: .piece,
                        error: nil,
                        isEditable: false,
                        startEditing: false
                    )
                )
            }

            shoppingListBinding.value = .reloadTable
            publishControlsState()
        } catch {
            show(error)
        }
    }

    private func makeListItems() -> [ListItem] {
        shoppingList.prefix(productCount).compactMap { item in
            guard item.error == nil,
                  let title = item.title?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !title.isEmpty else {
                return nil
            }

            return ListItem(name: title, quantity: item.quantity, unit: item.unit.rawValue, checked: item.checked)
        }
    }

    private func makeUniqueDuplicateTitle(existingNames: Set<String>) -> String {
        var copyNumber = 1
        var candidate = "\(currentListInfo.title) #\(copyNumber)"

        while existingNames.contains(normalizeName(candidate)) {
            copyNumber += 1
            candidate = "\(currentListInfo.title) #\(copyNumber)"
        }
        return candidate
    }

    private func moveItemInArray(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              shoppingList.indices.contains(sourceIndex),
              shoppingList.indices.contains(destinationIndex) else {
            return
        }

        let item = shoppingList.remove(at: sourceIndex)
        shoppingList.insert(item, at: destinationIndex)
    }

    private func normalizeName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private func publishControlsState() {
        shoppingListBinding.value = .updateBottomButton(getBottomButtonState())
        shoppingListBinding.value = .updateCheckAllAvailability(getCheckAllSwitchAvailability())
        shoppingListBinding.value = .updateCheckAllSwitch(getCheckAllSwitchState())
    }

    private func restoreList() {
        do {
            notificationService.cancelNotification(for: currentListInfo.listId)
            try storageService.restoreList(with: currentListInfo.listId)
            coordinator.popToMainView()
        } catch {
            show(error)
        }
    }

    private func saveListToStorage() {
        do {
            try storageService.updateList(list: ShopList(info: currentListInfo, items: makeListItems()))
        } catch {
            show(error)
        }
    }

    private func show(_ error: Error) {
        coordinator.showAlert(title: .errorTitle, message: error.localizedDescription)
    }

    private func validateName(at row: Int) -> Bool {
        guard shoppingList.indices.contains(row) else {
            return false
        }

        let oldError = shoppingList[row].error
        let title = shoppingList[row].title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        shoppingList[row].title = title
        shoppingList[row].startEditing = false

        if title.isEmpty {
            shoppingList[row].error = .newListEmptyName
        } else {
            shoppingList[row].error = nil
        }
        return oldError != shoppingList[row].error
    }
}

// MARK: - ShoppingListCellDelegate
extension ShoppingListViewModel: ShoppingListCellDelegate {

    func addNewItemButtonPressed() {
        guard !userIsTyping, shoppingList.prefix(productCount).allSatisfy({ $0.error == nil }) else {
            return
        }

        let index = uncheckedItemsCount
        shoppingList.insert(
            ShopListCellParams(
                id: UUID(),
                checked: false,
                title: nil,
                quantity: 1,
                unit: .piece,
                error: .newListEmptyName,
                isEditable: true,
                startEditing: true
            ),
            at: index
        )
        uncheckedItemsCount += 1
        userIsTyping = true
        publishControlsState()
        shoppingListBinding.value = .insertItem(IndexPath(row: index, section: 0))
    }

    func checkBoxTapped(cellID: UUID) {
        guard !currentListInfo.completed, !userIsTyping, let row = getItemRow(by: cellID) else {
            return
        }

        let wasChecked = shoppingList[row].checked
        shoppingList[row].checked.toggle()

        if wasChecked {
            let destination = uncheckedItemsCount
            if row == destination {
                shoppingListBinding.value = .updateItems([IndexPath(row: row, section: 0)], true)
            } else {
                moveItemInArray(from: row, to: destination)
                shoppingListBinding.value = .moveItem(
                    IndexPath(row: row, section: 0),
                    IndexPath(row: destination, section: 0)
                )
            }
            uncheckedItemsCount += 1
        } else {
            let destination = max(0, uncheckedItemsCount - 1)
            if row == destination {
                shoppingListBinding.value = .updateItems([IndexPath(row: row, section: 0)], true)
            } else {
                moveItemInArray(from: row, to: destination)
                shoppingListBinding.value = .moveItem(
                    IndexPath(row: row, section: 0),
                    IndexPath(row: destination, section: 0)
                )
            }
            uncheckedItemsCount -= 1
        }
        publishControlsState()
    }

    func editQuantityButtonPressed(cellID: UUID) {
        guard !currentListInfo.completed, !userIsTyping, let row = getItemRow(by: cellID) else {
            return
        }

        let item = shoppingList[row]
        shoppingListBinding.value = .showPopUp(cellID, item.quantity, item.unit)
    }

    func textFieldDidBeginEditing(cellID: UUID) {
        guard let row = getItemRow(by: cellID) else {
            return
        }

        shoppingList[row].startEditing = false
        userIsTyping = true
        publishControlsState()
    }

    func updateShoppingListItem(cellID: UUID, with title: String) {
        guard let row = getItemRow(by: cellID) else {
            return
        }

        let oldTitle = shoppingList[row].title
        shoppingList[row].title = title
        userIsTyping = false
        let validationChanged = validateName(at: row)
        publishControlsState()

        if validationChanged {
            shoppingListBinding.value = .updateItems([IndexPath(row: row, section: 0)], true)
        } else if oldTitle != shoppingList[row].title {
            saveListToStorage()
        }
    }
}

// MARK: - PopUpVCDelegate
extension ShoppingListViewModel: PopUpVCDelegate {

    func quantitySelected(itemID: UUID, quantity: Float) {
        guard let row = getItemRow(by: itemID) else {
            return
        }

        shoppingList[row].quantity = quantity
        shoppingListBinding.value = .updateItems([IndexPath(row: row, section: 0)], false)
    }

    func unitSelected(itemID: UUID, unit: Units) {
        guard let row = getItemRow(by: itemID) else {
            return
        }

        shoppingList[row].unit = unit
        shoppingListBinding.value = .updateItems([IndexPath(row: row, section: 0)], false)
    }
}

// MARK: - SuccessViewDelegate
extension ShoppingListViewModel: SuccessViewDelegate {

    func cancelButtonPressed() {
        coordinator.dismissPopupVC()
    }

    func confirmButtonPressed() {
        do {
            notificationService.cancelNotification(for: currentListInfo.listId)

            if currentListInfo.pinned {
                let archivedInfo = ListInfo(
                    listId: UUID(),
                    title: currentListInfo.title,
                    date: Date(),
                    completed: true,
                    pinned: false
                )
                try storageService.saveNewList(list: ShopList(info: archivedInfo, items: makeListItems()))
                (0..<productCount).forEach { shoppingList[$0].checked = false }
                currentListInfo.setReminderDate(to: nil)
            } else {
                currentListInfo.setCompleted(to: true)
                currentListInfo.setReminderDate(to: nil)
            }

            try storageService.updateList(list: ShopList(info: currentListInfo, items: makeListItems()))
            coordinator.dismissPopupVC { [weak self] in
                self?.coordinator.switchToMainView()
            }
        } catch {
            coordinator.dismissPopupVC { [weak self] in
                self?.show(error)
            }
        }
    }
}

// MARK: - DatePickerViewDelegate
extension ShoppingListViewModel: DatePickerViewDelegate {

    func datePickerCancelButtonPressed() {
        coordinator.dismissPopupVC()
    }

    func datePickerConfirmButtonPressed(date: Date) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            do {
                try await self.notificationService.scheduleNotification(
                    for: self.currentListInfo.listId,
                    listTitle: self.currentListInfo.title,
                    date: date
                )
                self.currentListInfo.setReminderDate(to: date)
                do {
                    try self.storageService.updateListInfo(listInfo: self.currentListInfo)
                    self.coordinator.dismissPopupVC { [weak self] in
                        self?.coordinator.showAlert(
                            title: .notificationScheduledTitle,
                            message: .notificationScheduledMessage
                        )
                    }
                } catch {
                    self.notificationService.cancelNotification(for: self.currentListInfo.listId)
                    self.coordinator.dismissPopupVC { [weak self] in
                        self?.show(error)
                    }
                }
            } catch {
                self.coordinator.dismissPopupVC { [weak self] in
                    if error as? NotificationServiceError == .permissionDenied {
                        self?.coordinator.showNotificationPermissionAlert()
                    } else {
                        self?.show(error)
                    }
                }
            }
        }
    }
}
