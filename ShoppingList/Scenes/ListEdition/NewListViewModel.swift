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
    private let dispatcher = ConcurrentDispatcher()
    private let editList: UUID?
    private var existingListNames = Set<String>()
    private var listItems: [NewListCellParams] = []
    private var editedList: ShopList?
    private var autoSave = true
    private var listIsValid: Bool = false
    private var userIsTyping: Bool = false
    private var state: States? {
        didSet {
            processState()
        }
    }
    
    private enum States {
        case loadList
        case checkList(itemUpdated: Int?)
        case startEditing(row: Int, field: Fields)
        case itemModified(row: Int, newValue: Values)
        case deleteItem(row: Int)
        case addNewItem
        case saveList
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
                .init(row: row,
                      title: listItems[row].title,
                      quantity: listItems[row].quantity,
                      unit: listItems[row].unit,
                      error: listItems[row].error,
                      startEditing: listItems[row].startEditing
                     )
        )
    }
    
    func getCompleteButtonState() -> Bool {
        listIsValid
    }
    
    func tableFinishedUpdating() {
        userIsTyping = false
    }
    
    // MARK: - Actions
    func completeButtonPressed() {
        state = .saveList
    }
    
    func deleteItemButtonPressed(in row: Int) {
        state = .deleteItem(row: row)
    }
    
    // MARK: - Private Methods
    private func processState() {
        switch state {
            
        case .loadList:
            dispatcher.async {
                self.setListItems()
            }
            
            dispatcher.asyncBarrier {
                if self.updateCompleteButtonState() {
                    self.newListBinding.value = [.updateCompleteButtonState]
                }
                //                self.state = .checkList(itemUpdated: nil)
            }
            
        case .checkList(itemUpdated: let itemUpdated):
            var indexesToReload: [IndexPath] = []
            var bindingTasks = [NewListBinding]()
            
            dispatcher.async {
                if let itemUpdated {
                    if self.validateName(row: itemUpdated) {
                        indexesToReload.append(IndexPath(row: itemUpdated, section: 0))
                    }
                } else {
                    for row in 0...self.listItems.count - 2 {
                        if self.validateName(row: row) {
                            indexesToReload.append(IndexPath(row: row, section: 0))
                        }
                    }
                }
            }
            dispatcher.asyncBarrier {
                if !indexesToReload.isEmpty {
                    bindingTasks.append(.updateItems(indexesToReload, true))
                }
            }
            
            dispatcher.asyncBarrier {
                if self.updateCompleteButtonState() {
                    bindingTasks.append(.updateCompleteButtonState)
                }
            }
            
            dispatcher.asyncBarrier {
                if !bindingTasks.isEmpty {
                    self.newListBinding.value = bindingTasks
                }
            }
            
        case .startEditing(row: let row, field: let field):
            var bindingTasks: [NewListBinding] = []
            
            switch field {
            case .name:
                self.userIsTyping = true
            case .quantity:
                guard userIsTyping else { return }
                bindingTasks.append(.showPopUp(row, listItems[row].quantity ?? 1, listItems[row].unit ?? .piece))
            }
            
            if !bindingTasks.isEmpty {
                newListBinding.value = bindingTasks
            }
            
        case .itemModified(row: let row, newValue: let newValue):
            switch newValue {
            case .name(let newName):
                print("@@@    textFieldDidEndEditing")
                listItems[row].title = newName
                state = .checkList(itemUpdated: row)
                
            case .quantity(let newQuantity):
                listItems[row].quantity = newQuantity
                
            case .unit(let newUnit):
                listItems[row].unit = newUnit
            }
            userIsTyping = false
            
        case .addNewItem:
            guard userIsTyping,
                  !listIsValid else {
                return
            }
            
            dispatcher.async {
                self.listIsValid = false
                self.listItems.insert(.init(row: self.listItems.count - 1,
                                            quantity: 1,
                                            unit: .piece,
                                            startEditing: true
                                           ), at: self.listItems.count - 1
                )
            }
            
            dispatcher.asyncBarrier {
                self.newListBinding.value = [
                    .insertItem(.init(row: self.listItems.count - 2, section: 0)),
                    .updateCompleteButtonState
                ]
            }
            
        case .deleteItem(row: let row):
            dispatcher.async {
                self.listItems.remove(at: row)
            }
            dispatcher.asyncBarrier {
                self.newListBinding.value = [.removeItem(.init(row: row, section: 0))]
            }
            dispatcher.asyncBarrier {
                self.state = .checkList(itemUpdated: nil)
            }
            
        case .saveList:
            guard !userIsTyping,
                  listIsValid else {
                return
            }
    
            dispatcher.async {
                self.state = .checkList(itemUpdated: nil)
            }
            
            dispatcher.asyncBarrier {
                if self.listIsValid {
                    DispatchQueue.main.async {
                        self.autoSave = false
                        self.editList == nil
                        ? self.storageService.saveNewList(list: self.buildNewList())
                        : self.storageService.updateList(list: self.buildNewList())
                        self.coordinator.popToMainView()
                    }
                }
            }
            
            
        case .viewWillDisappear:
            if autoSave {
                saveUserInputs()
            }
            
        case .wipeInputs:
            listItems = [
                .init(row: 0, title: nil),
                .init(row: listItems.count, title: .buttonAddProduct)
            ]
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
        listItems = [.init(row: 0, title: editedList?.info.title)]
        for (index, item) in (editedList?.items ?? []).enumerated() {
            listItems.append(.init(row: index + 1,
                                   title: item.name,
                                   quantity: Float(item.quantity),
                                   unit: Units(rawValue: item.unit) ?? .piece
                                  )
            )
        }
        listItems.append(.init(row: listItems.count, title: .buttonAddProduct))
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
                .init(row: 0),//, error: .newListEmptyName),
                .init(row: 1, title: .buttonAddProduct)
            ]
            return
        }
        
        listItems = [.init(row: 0, title: UserDefaults.standard.string(forKey: "newListTitle"))]
        
        let itemsCount = UserDefaults.standard.integer(forKey: "newListItemsCount")
        
        if itemsCount > 0 {
            for i in 1...itemsCount {
                listItems.append(
                    .init(row: i,
                          title: UserDefaults.standard.string(forKey: "newListItem\(i).title"),
                          quantity: UserDefaults.standard.float(forKey: "newListItem\(i).quantity"),
                          unit: Units(rawValue: UserDefaults.standard.string(forKey: "newListItem\(i).unit")
                                      ?? Units.piece.rawValue) ?? .piece,
                          checked: false
                         )
                )
            }
        }
        listItems.append(.init(row: listItems.count, title: .buttonAddProduct))
        clearSavedUserInputs()
    }
    
    private func clearSavedUserInputs() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
    
    @discardableResult
    private func updateCompleteButtonState() -> Bool { // возвращает true если статус изменился
        let oldState = listIsValid
        listIsValid = validateList()
        return oldState != listIsValid
    }
    
    @discardableResult
    private func validateName(row: Int) -> Bool { // возвращает true если статус изменился
        let oldErrorStatus = listItems[row].error
        
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
        //        listItems.first(where: {$0.error != nil}) == nil
    }
    
}

// MARK: - NewListCellDelegate
extension NewListViewModel: NewListCellDelegate {
    
    func updateNewListTitle(with title: String?) {
        
        state = .itemModified(row: 0, newValue: .name(title))
    }
    
    func updateNewListItem(in row: Int, with title: String?) {
        state = .itemModified(row: row, newValue: .name(title))
    }
    
    func textFieldDidBeginEditing(in: Int) {
        state = .startEditing(row: 0, field: .name)
    }
    
    func editQuantityButtonPressed(in row: Int) {
        state = .startEditing(row: row, field: .quantity)
    }
    
    func addNewItemButtonPressed() {
        state = .addNewItem
    }
}

// MARK: - PopUpVCDelegate
extension NewListViewModel: PopUpVCDelegate {
    func unitSelected(item: Int, unit: Units) {
        state = .itemModified(row: item, newValue: .unit(unit))
    }
    
    func quantitySelected(item: Int, quantity: Float) {
        state = .itemModified(row: item, newValue: .quantity(quantity))
    }
}
