import Foundation

protocol NewListViewModelProtocol {
    var newListBinding: Observable<NewListBinding> { get set }
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
    var newListBinding: Observable<NewListBinding> = Observable(nil)
    
    // MARK: - Private Properties
    private let coordinator: Coordinator
    private let storageService: StorageServiceProtocol
    private let editList: UUID?
    private var existingListNames = Set<String>()
    private var listItems: [NewListCellParams] = []
    private var editedList: ShopList?
    private var autoSave = true
    private var completeButtonIsEnabled: Bool = false
    private var userIsTyping: Bool = false
    
    // MARK: - Initializers
    init(coordinator: Coordinator, editList: UUID?) {
        self.coordinator = coordinator
        self.storageService = coordinator.storageService
        self.editList = editList
    }
    
    // MARK: - Public Methods
    func viewWillAppear() {
        self.existingListNames = storageService.getExistingListNames()
        setListItems()
        updateCompleteButtonState()
    }
    
    func viewWillDisappear() {
        if autoSave {
            saveUserInputs()
        }
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
                      error: listItems[row].error
                     )
        )
    }
    
    func getCompleteButtonState() -> Bool {
        completeButtonIsEnabled
    }
    
    func tableFinishedUpdating() {
        userIsTyping = false
    }
    
    
    // MARK: - Actions
    func completeButtonPressed() {
        autoSave = false
        editList == nil
        ? storageService.saveNewList(list: buildNewList())
        : storageService.updateList(list: buildNewList())
        coordinator.popToMainView()
    }
    
    func deleteItemButtonPressed(in row: Int) {
        listItems.remove(at: row)
        updateCompleteButtonState()
        newListBinding.value = .removeItem(.init(row: row, section: 0))
    }
    
    // MARK: - Private Methods
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
                                   unit: Units(rawValue: item.unit) ?? .piece,
                                   checked: item.checked
                                  )
            )
        }
        listItems.append(.init(row: listItems.count, title: .buttonAddProduct))
    }
    
    @discardableResult
    private func validateName(row: Int) -> Bool { // возвращает true если статус изменился
        guard let newTitle = listItems[row].title else {
            return false
        }
        
        let oldErrorStatus = listItems[row].error
        
        if newTitle.isEmpty {
            listItems[row].error = .newListEmptyName
            
        } else if row == 0,
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
    
    @discardableResult
    private func updateCompleteButtonState() -> Bool { // возвращает true если статус изменился
        let oldState = completeButtonIsEnabled
        completeButtonIsEnabled = validateList()
        return oldState != completeButtonIsEnabled
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
        guard UserDefaults.standard.bool(forKey: "newListInputsSaved") == true  else {
            listItems = [
                .init(row: 0),
                .init(row: 1, title: .buttonAddProduct)
            ]
            return
        }
        
        listItems = [.init(row: 0, title: UserDefaults.standard.string(forKey: "newListTitle"))]
        if listItems[0].title != nil {
            validateName(row: 0)
        }
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
                if listItems[i].title != nil {
                    validateName(row: i)
                }
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
}

// MARK: - NewListCellDelegate
extension NewListViewModel: NewListCellDelegate {
    
    func updateNewListTitle(with title: String?) {
        listItems[0].title = title
        let itemErrorUpdated = validateName(row: 0)
        let buttonStateUpdated = updateCompleteButtonState()
        
        if itemErrorUpdated {
            newListBinding.value = .updateItem(IndexPath(row: 0, section: 0), true)
            
        } else if buttonStateUpdated {
            newListBinding.value = .updateCompleteButtonState
            
        } else {
            userIsTyping = false
        }
    }
    
    func updateNewListItem(in row: Int, with title: String?) {
        listItems[row].title = title
        let itemErrorUpdated = validateName(row: row)
        let buttonStateUpdated = updateCompleteButtonState()
        
        if itemErrorUpdated {
            newListBinding.value = .updateItem(IndexPath(row: row, section: 0), true)
            
        } else if buttonStateUpdated {
            newListBinding.value = .updateCompleteButtonState
            
        } else {
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
        guard !userIsTyping,
              completeButtonIsEnabled else { return }
        newListBinding.value = .showPopUp(row, listItems[row].quantity ?? 1, listItems[row].unit ?? .piece)
    }
    
    func addNewItemButtonPressed() {
        guard !userIsTyping,
              completeButtonIsEnabled else { return }
        listItems.insert(.init(row: listItems.count - 1,
                               quantity: 1,
                               unit: .piece
                              ), at: listItems.count - 1
        )
        newListBinding.value = .insertItem(.init(row: listItems.count - 2, section: 0))
        updateCompleteButtonState()
    }
}

// MARK: - PopUpVCDelegate
extension NewListViewModel: PopUpVCDelegate {
    func unitSelected(item: Int, unit: Units) {
        listItems[item].unit = unit
        newListBinding.value = .updateItem(.init(row: item, section: 0), false)
    }
    
    func quantitySelected(item: Int, quantity: Float) {
        listItems[item].quantity = quantity
        newListBinding.value = .updateItem(.init(row: item, section: 0), false)
    }
}
