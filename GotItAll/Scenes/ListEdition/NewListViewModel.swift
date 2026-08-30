import Foundation

protocol NewListViewModelProtocol: AnyObject {
    var newListBinding: Observable<[NewListBinding]> { get set }

    func completeButtonPressed()
    func deleteItemButtonPressed(in row: Int)
    func getCellParams(for row: Int) -> (NewListCellType, NewListCellParams)
    func getCompleteButtonState() -> Bool
    func getListTitle() -> String
    func getRowHeight(for row: Int) -> CGFloat
    func getTableRowCount() -> Int
    func tableFinishedUpdating()
    func viewWillAppear()
    func viewWillDisappear()
}

final class NewListViewModel: NewListViewModelProtocol {

    // MARK: - Public Properties
    var newListBinding: Observable<[NewListBinding]> = Observable(nil)

    // MARK: - Private Properties
    private let coordinator: Coordinator
    private let editListID: UUID?
    private let listID: UUID
    private let notificationService: NotificationServiceProtocol
    private let storageService: StorageServiceProtocol
    private var completeButtonState = false
    private var completeButtonWasPressed = false
    private var editedList: ShopList?
    private var existingListNames = Set<String>()
    private var hasLoaded = false
    private var listItems: [NewListCellParams] = []
    private var tableIsUpdating = false
    private var userIsTyping = false

    private var productRange: Range<Int> {
        guard listItems.count > 2 else {
            return 1..<1
        }
        return 1..<(listItems.count - 1)
    }

    // MARK: - Initializers
    init(coordinator: Coordinator, editList: UUID?) {
        self.coordinator = coordinator
        editListID = editList
        listID = editList ?? UUID()
        notificationService = coordinator.notificationService
        storageService = coordinator.storageService
    }

    // MARK: - Public Methods
    func completeButtonPressed() {
        guard !userIsTyping else {
            return
        }

        let changedRows = validateAllNames()
        guard changedRows.isEmpty, validateList() else {
            if !changedRows.isEmpty {
                tableIsUpdating = true
                newListBinding.value = [.updateItems(changedRows, true)]
            }
            updateCompleteButtonState()
            return
        }

        do {
            completeButtonWasPressed = true
            try saveList()
            coordinator.popToMainView()
        } catch {
            completeButtonWasPressed = false
            show(error)
        }
    }

    func deleteItemButtonPressed(in row: Int) {
        guard productRange.contains(row) else {
            return
        }

        listItems.remove(at: row)
        tableIsUpdating = true
        newListBinding.value = [.removeItem(IndexPath(row: row, section: 0))]
    }

    func getCellParams(for row: Int) -> (NewListCellType, NewListCellParams) {
        let type: NewListCellType
        if row == 0 {
            type = .title
        } else if row == listItems.count - 1 {
            type = .button
        } else {
            type = .item
        }
        return (type, listItems[row])
    }

    func getCompleteButtonState() -> Bool {
        completeButtonState
    }

    func getListTitle() -> String {
        editListID == nil ? .newListCreationTitle : .buttonEdit
    }

    func getRowHeight(for row: Int) -> CGFloat {
        if row == 0 {
            return listItems[row].error == nil ? 60 : 87
        }
        if row == listItems.count - 1 {
            return 76
        }
        return listItems[row].error == nil ? 52 : 81
    }

    func getTableRowCount() -> Int {
        listItems.count
    }

    func tableFinishedUpdating() {
        tableIsUpdating = false
        updateCompleteButtonState()
    }

    func viewWillAppear() {
        guard !hasLoaded else {
            return
        }

        do {
            existingListNames = try storageService.getExistingListNames(excluding: editListID)
            try loadListItems()
            hasLoaded = true
            completeButtonState = validateList()
            newListBinding.value = [.reloadTable, .updateCompleteButtonState]
        } catch {
            show(error)
        }
    }

    func viewWillDisappear() {
        guard !completeButtonWasPressed, validateList() else {
            return
        }

        do {
            try saveList()
        } catch {
            show(error)
        }
    }

    // MARK: - Private Methods
    private func buildList() -> ShopList {
        let items = productRange.compactMap { index -> ListItem? in
            let item = listItems[index]
            guard item.error == nil,
                  let title = item.title?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !title.isEmpty else {
                return nil
            }

            return ListItem(
                name: title,
                quantity: item.quantity ?? 1,
                unit: item.unit?.rawValue ?? Units.piece.rawValue,
                checked: item.checked ?? false
            )
        }
        let info = ListInfo(
            listId: listID,
            title: listItems[0].title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            date: editedList?.info.date ?? Date(),
            completed: editedList?.info.completed ?? false,
            pinned: editedList?.info.pinned ?? false,
            reminderDate: editedList?.info.reminderDate.flatMap { $0 > Date() ? $0 : nil }
        )
        return ShopList(info: info, items: items)
    }

    private func getItemRow(by id: UUID) -> Int? {
        listItems.firstIndex { $0.id == id }
    }

    private func loadListItems() throws {
        guard let editListID else {
            listItems = [
                NewListCellParams(id: UUID()),
                NewListCellParams(id: UUID(), title: .buttonAddProduct)
            ]
            return
        }

        guard let storedList = try storageService.getList(by: editListID) else {
            throw StorageServiceError.listNotFound
        }

        editedList = storedList
        listItems = [NewListCellParams(id: UUID(), title: storedList.info.title)]
        storedList.items.forEach { item in
            listItems.append(
                NewListCellParams(
                    id: UUID(),
                    title: item.name,
                    quantity: item.quantity,
                    unit: Units(rawValue: item.unit) ?? .piece,
                    checked: item.checked
                )
            )
        }
        listItems.append(NewListCellParams(id: UUID(), title: .buttonAddProduct))
    }

    private func normalizeName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private func saveList() throws {
        let list = buildList()
        if editListID == nil {
            try storageService.saveNewList(list: list)
        } else {
            try storageService.updateList(list: list)
        }

        guard let reminderDate = list.info.reminderDate else {
            notificationService.cancelNotification(for: list.info.listId)
            return
        }

        Task { @MainActor [weak self, notificationService] in
            do {
                try await notificationService.scheduleNotification(
                    for: list.info.listId,
                    listTitle: list.info.title,
                    date: reminderDate
                )
            } catch {
                self?.show(error)
            }
        }
    }

    private func show(_ error: Error) {
        coordinator.showAlert(title: .errorTitle, message: error.localizedDescription)
    }

    private func updateCompleteButtonState() {
        let newState = validateList()
        guard completeButtonState != newState else {
            return
        }

        completeButtonState = newState
        newListBinding.value = [.updateCompleteButtonState]
    }

    private func validateAllNames() -> [IndexPath] {
        (0..<(listItems.count - 1)).compactMap { row in
            validateName(at: row) ? IndexPath(row: row, section: 0) : nil
        }
    }

    private func validateList() -> Bool {
        guard !listItems.isEmpty else {
            return false
        }

        return (0..<(listItems.count - 1)).allSatisfy { row in
            let title = listItems[row].title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !title.isEmpty && listItems[row].error == nil
        }
    }

    @discardableResult
    private func validateName(at row: Int) -> Bool {
        guard listItems.indices.contains(row), row < listItems.count - 1 else {
            return false
        }

        let oldError = listItems[row].error
        let title = listItems[row].title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        listItems[row].title = title
        listItems[row].startEditing = false

        if title.isEmpty {
            listItems[row].error = .newListEmptyName
        } else if row == 0, existingListNames.contains(normalizeName(title)) {
            listItems[row].error = .newListNameAlreadyUsed
        } else {
            listItems[row].error = nil
        }
        return oldError != listItems[row].error
    }
}

// MARK: - NewListCellDelegate
extension NewListViewModel: NewListCellDelegate {

    func addNewItemButtonPressed() {
        guard !userIsTyping, !tableIsUpdating, validateList() else {
            return
        }

        let index = listItems.count - 1
        listItems.insert(
            NewListCellParams(
                id: UUID(),
                quantity: 1,
                unit: .piece,
                startEditing: true
            ),
            at: index
        )
        tableIsUpdating = true
        userIsTyping = true
        newListBinding.value = [
            .insertItem(IndexPath(row: index, section: 0)),
            .updateCompleteButtonState
        ]
    }

    func editQuantityButtonPressed(id: UUID) {
        guard !userIsTyping, let row = getItemRow(by: id), productRange.contains(row) else {
            return
        }

        let item = listItems[row]
        newListBinding.value = [.showPopUp(id, item.quantity ?? 1, item.unit ?? .piece)]
    }

    func textFieldDidBeginEditing(id: UUID) {
        guard let row = getItemRow(by: id) else {
            return
        }

        listItems[row].startEditing = false
        userIsTyping = true
    }

    func updateNewListItem(id: UUID, with title: String?) {
        guard let row = getItemRow(by: id) else {
            return
        }

        updateName(at: row, title: title)
    }

    func updateNewListTitle(with title: String?) {
        updateName(at: 0, title: title)
    }

    // MARK: - Private Methods
    private func updateName(at row: Int, title: String?) {
        listItems[row].title = title
        userIsTyping = false

        if validateName(at: row) {
            tableIsUpdating = true
            newListBinding.value = [.updateItems([IndexPath(row: row, section: 0)], true)]
        } else {
            updateCompleteButtonState()
        }
    }
}

// MARK: - PopUpVCDelegate
extension NewListViewModel: PopUpVCDelegate {

    func quantitySelected(itemID: UUID, quantity: Float) {
        guard let row = getItemRow(by: itemID), productRange.contains(row) else {
            return
        }

        listItems[row].quantity = quantity
        tableIsUpdating = true
        newListBinding.value = [.updateItems([IndexPath(row: row, section: 0)], false)]
    }

    func unitSelected(itemID: UUID, unit: Units) {
        guard let row = getItemRow(by: itemID), productRange.contains(row) else {
            return
        }

        listItems[row].unit = unit
        tableIsUpdating = true
        newListBinding.value = [.updateItems([IndexPath(row: row, section: 0)], false)]
    }
}
