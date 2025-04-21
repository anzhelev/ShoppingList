import Foundation

protocol NewListViewModelProtocol {
    var newListBinding: Observable<[NewListBinding]> { get set }
    func viewWillAppear()
    func viewWillDisappear()
    func completeButtonPressed()
    func getListTitle() -> String
    func getTableRowCount() -> Int
    func getRowHeight(for row: Int) -> CGFloat
    func getCellParams(for row: Int) -> (NewListCellType, NewListCellParams)
    func getCompleteButtonState() -> Bool
    func deleteItemButtonPressed(in row: Int)
    func tableFinishedUpdating()
}

final class NewListViewModel: NewListViewModelProtocol {
    
    // MARK: - Public Properties
    var newListBinding: Observable<[NewListBinding]> = Observable(nil)
    
    // MARK: - Private Properties
    private let coordinator: Coordinator
    private let storageService: StorageServiceProtocol
    private let editList: UUID?
    private var existingListNames = Set<String>()
    private var listItems: [NewListCellParams] = []
    private var editedList: ShopList?
    private var autoSave = true
    private var userIsTyping: Bool = false
    private var tableIsUpdating: Bool = false
    private var completeButtonState: Bool = true
    
    private var listIsValid: Bool {
        validateList()
    }
    
    private var state: States? {
        didSet {
            processState()
        }
    }
    
    private var addNewItemButtonIsEnabled: Bool {
        !userIsTyping && !tableIsUpdating && listIsValid
    }
    
    private enum States {
        case loadList
        case validateNames(itemUpdated: Int?)
        case startEditing(row: Int, field: Fields)
        case itemModified(row: Int, newValue: Values)
        case deleteItem(row: Int)
        case addNewItem
        case completeButtonPressed
        case viewWillDisappear
        case wipeInputs
    }
    
    private enum Values {
        case name(String?)
        case quantity(Float)
        case unit(Units)
    }
    
    private enum Fields {
        case name
        case quantity
    }
    
    // MARK: - Initializers
    init(coordinator: Coordinator, editList: UUID?) {
        self.coordinator = coordinator
        self.storageService = coordinator.storageService
        self.editList = editList
    }
    
    // MARK: - Public Methods
    func viewWillAppear() {
        self.state = .loadList
    }
    
    func viewWillDisappear() {
        state = .viewWillDisappear
    }
    
    func getListTitle() -> String {
        editList == nil ? .newListCreationTitle : .buttonEdit
    }
    
    func getTableRowCount() -> Int {
        listItems.count
    }
    
    func getRowHeight(for row: Int) -> CGFloat {
        switch row {
            
        case 0:
            listItems[row].error == nil ? 60 : 87
            
        case listItems.count - 1:
            76
            
        default:
            listItems[row].error == nil ? 52 : 81
        }
    }
    
    func getCellParams(for row: Int) -> (NewListCellType, NewListCellParams) {
        return (row == 0 ? .title : row == listItems.count - 1 ? .button : .item,
                .init(id: listItems[row].id,
                      title: listItems[row].title,
                      quantity: listItems[row].quantity,
                      unit: listItems[row].unit,
                      error: listItems[row].error,
                      startEditing: listItems[row].startEditing
                     )
        )
    }
    
    func getCompleteButtonState() -> Bool {
        completeButtonState
    }
    
    func tableFinishedUpdating() {
        tableIsUpdating = false
        if updateCompleteButtonState() {
            newListBinding.value = [.updateCompleteButtonState]
        }
    }
    
    // MARK: - Actions
    func completeButtonPressed() {
        state = .completeButtonPressed
    }
    
    func deleteItemButtonPressed(in row: Int) {
        state = .deleteItem(row: row)
    }
    
    // MARK: - Private Methods
    private func processState() {
        switch state {
            
        case .loadList:
            setListItems()
            state = .validateNames(itemUpdated: nil)
            
        case .validateNames(itemUpdated: let itemUpdated):
            var indexesToReload: [IndexPath] = []
            var bindingTasks = [NewListBinding]()
            
            if let itemUpdated {
                if validateName(row: itemUpdated) {
                    indexesToReload.append(IndexPath(row: itemUpdated, section: 0))
                }
            } else {
                for row in 0...listItems.count - 2 {
                    if validateName(row: row) {
                        indexesToReload.append(IndexPath(row: row, section: 0))
                    }
                }
            }
            
            if !indexesToReload.isEmpty {
                bindingTasks.append(.updateItems(indexesToReload, true))
                tableIsUpdating = true
                newListBinding.value = bindingTasks
            } else if updateCompleteButtonState() {
                newListBinding.value = [.updateCompleteButtonState]
            }
            
        case .startEditing(row: let row, field: let field):
            switch field {
            case .name:
                userIsTyping = true
            case .quantity:
                guard !userIsTyping else { return }
                newListBinding.value = [.showPopUp(listItems[row].id, listItems[row].quantity ?? 1, listItems[row].unit ?? .piece)]
            }
            
        case .itemModified(row: let row, newValue: let newValue):
            switch newValue {
            case .name(let newName):
                listItems[row].title = newName
                state = .validateNames(itemUpdated: row)
            case .quantity(let newQuantity):
                listItems[row].quantity = newQuantity
                tableIsUpdating = true
                newListBinding.value = [.updateItems([.init(row: row, section: 0)], false)]
            case .unit(let newUnit):
                listItems[row].unit = newUnit
                tableIsUpdating = true
                newListBinding.value = [.updateItems([.init(row: row, section: 0)], false)]
            }
            userIsTyping = false
            
        case .addNewItem:
            guard self.addNewItemButtonIsEnabled else {
                return
            }
            
            DispatchQueue.main.async {
                let newItemIndex = self.listItems.count - 1
                self.listItems.insert(.init(id: UUID(),
                                            quantity: 1,
                                            unit: .piece,
                                            startEditing: true
                                           ), at: newItemIndex
                )
                self.tableIsUpdating = true
                self.newListBinding.value = [
                    .insertItem(.init(row: self.listItems.count - 2, section: 0)),
                    .updateCompleteButtonState
                ]
            }
            
        case .deleteItem(row: let row):
            DispatchQueue.main.async {
                self.listItems.remove(at: row)
                self.tableIsUpdating = true
                self.newListBinding.value = [.removeItem(.init(row: row, section: 0))]
            }
            
        case .completeButtonPressed:
            guard !userIsTyping else { return }
            
            state = .validateNames(itemUpdated: nil)
            
            if listIsValid {
                DispatchQueue.main.async {
                    self.autoSave = false
                    self.editList == nil
                    ? self.storageService.saveNewList(list: self.buildNewList())
                    : self.storageService.updateList(list: self.buildNewList())
                    self.coordinator.popToMainView()
                }
            }
            
        case .viewWillDisappear:
            if autoSave {
                saveUserInputs()
            }
            
        case .wipeInputs:
            listItems = [
                .init(id: UUID(), title: nil),
                .init(id: UUID(), title: .buttonAddProduct)
            ]
            tableIsUpdating = true
            newListBinding.value = [.reloadTable]
            
        default:
            break
        }
    }
    
    private func setListItems() {
        guard let editList else {
            restoreUserInputs()
            return
        }
        editedList = storageService.getList(by: editList)
        listItems = [.init(id: UUID(), title: editedList?.info.title)]
        for item in editedList?.items ?? [] {
            listItems.append(.init(id: UUID(),
                                   title: item.name,
                                   quantity: Float(item.quantity),
                                   unit: Units(rawValue: item.unit) ?? .piece
                                  )
            )
        }
        listItems.append(.init(id: UUID(), title: .buttonAddProduct))
    }
    
    private func buildNewList() -> ShopList {
        var newListItems = [ListItem]()
        if listItems.count > 2 {
            for item in listItems[1...listItems.count - 2] {
                newListItems.append(.init(name: item.title ?? .newListItemPlaceholder,
                                          quantity: Float(item.quantity ?? 1),
                                          unit: item.unit?.rawValue ?? Units.piece.rawValue,
                                          checked: item.checked ?? false
                                         )
                )
            }
        }
        return .init(info: .init(listId: editList ?? UUID(),
                                 title: listItems[0].title ?? .newListCreationTitle,
                                 date: editedList?.info.date ?? Date(),
                                 completed: editList == nil ? false : editedList?.info.completed ?? false,
                                 pinned: editList == nil ? false : editedList?.info.pinned ?? false
                                ),
                     items: newListItems
        )
    }
    
    private func getItemRowBy(id: UUID) -> Int {
        listItems.firstIndex(where: { $0.id == id }) ?? 0
    }
    
    private func saveUserInputs() {
        guard editList == nil,
              listItems[0].title != nil || listItems.count > 2  else {
            UserDefaults.standard.set(false, forKey: "newListInputsSaved")
            return
        }
        UserDefaults.standard.set(true, forKey: "newListInputsSaved")
        UserDefaults.standard.set(listItems[0].title, forKey: "newListTitle")
        let itemsCount = listItems.count - 2
        UserDefaults.standard.set(itemsCount, forKey: "newListItemsCount")
        
        if itemsCount > 0 {
            for i in 1...itemsCount {
                UserDefaults.standard.set(listItems[i].title, forKey: "newListItem\(i).title")
                UserDefaults.standard.set(listItems[i].quantity, forKey: "newListItem\(i).quantity")
                UserDefaults.standard.set(listItems[i].unit?.rawValue, forKey: "newListItem\(i).unit")
            }
        }
    }
    
    private func restoreUserInputs() {
        guard UserDefaults.standard.bool(forKey: "newListInputsSaved") == true else {
            listItems = [
                .init(id: UUID()),//, error: .newListEmptyName),
                .init(id: UUID(), title: .buttonAddProduct)
            ]
            return
        }
        
        listItems = [.init(id: UUID(), title: UserDefaults.standard.string(forKey: "newListTitle"))]
        
        let itemsCount = UserDefaults.standard.integer(forKey: "newListItemsCount")
        
        if itemsCount > 0 {
            for i in 1...itemsCount {
                listItems.append(
                    .init(id: UUID(),
                          title: UserDefaults.standard.string(forKey: "newListItem\(i).title"),
                          quantity: UserDefaults.standard.float(forKey: "newListItem\(i).quantity"),
                          unit: Units(rawValue: UserDefaults.standard.string(forKey: "newListItem\(i).unit")
                                      ?? Units.piece.rawValue) ?? .piece,
                          checked: false
                         )
                )
            }
        }
        listItems.append(.init(id: UUID(), title: .buttonAddProduct))
        clearSavedUserInputs()
    }
    
    private func clearSavedUserInputs() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
    
    @discardableResult
    private func updateCompleteButtonState() -> Bool { // возвращает true если статус изменился
        let oldState = completeButtonState
        completeButtonState = validateList()
        return oldState != completeButtonState
    }
    
    @discardableResult
    private func validateName(row: Int) -> Bool { // возвращает true если статус изменился
        let oldErrorStatus = listItems[row].error
        listItems[row].startEditing = false
        
        guard let newTitle = listItems[row].title,
              !newTitle.isEmpty else {
            listItems[row].error = .newListEmptyName
            return oldErrorStatus != listItems[row].error
        }
        
        if row == 0,
           existingListNames.contains(newTitle.lowercased()) && editedList == nil {
            listItems[row].error = .newListNameAlreadyUsed
            
        } else if newTitle.replacingOccurrences(of: " ", with: "").isEmpty {
            listItems[row].error = .newListWrongName
            
        } else {
            listItems[row].error = nil
        }
        
        return oldErrorStatus != listItems[row].error
    }
    
    private func validateList() -> Bool {
        listItems.first(where: { $0.title == nil || $0.title?.isEmpty == true || $0.error != nil}) == nil
    }
    
}

// MARK: - NewListCellDelegate
extension NewListViewModel: NewListCellDelegate {
    
    func updateNewListTitle(with title: String?) {
        
        state = .itemModified(row: 0, newValue: .name(title))
    }
    
    func updateNewListItem(id: UUID, with title: String?) {
        state = .itemModified(row: getItemRowBy(id: id), newValue: .name(title))
    }
    
    func textFieldDidBeginEditing(id: UUID) {
        state = .startEditing(row: getItemRowBy(id: id), field: .name)
    }
    
    func editQuantityButtonPressed(id: UUID) {
        state = .startEditing(row: getItemRowBy(id: id), field: .quantity)
    }
    
    func addNewItemButtonPressed() {
        state = .addNewItem
    }
}

// MARK: - PopUpVCDelegate
extension NewListViewModel: PopUpVCDelegate {
    func unitSelected(itemID: UUID, unit: Units) {
        state = .itemModified(row: getItemRowBy(id: itemID), newValue: .unit(unit))
    }
    
    func quantitySelected(itemID: UUID, quantity: Float) {
        state = .itemModified(row: getItemRowBy(id: itemID), newValue: .quantity(quantity))
    }
}
