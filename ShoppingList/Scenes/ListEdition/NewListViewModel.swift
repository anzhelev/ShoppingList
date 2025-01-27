import Foundation

protocol NewListViewModelProtocol {
    var needToUpdateCompleteButtonState: Observable<Bool> { get set }
    var userInteractionEnabled: Observable<Bool> { get set }
    var switchToMainView: Observable<Bool> { get set }
    var needToClosePopUp: Observable<Bool> { get set }
    var popUpQuantity: Observable<Int> { get set }
    var popUpUnit: Observable<Int> { get set }
    var needToShowPopUp: Observable<(Int, Int, Units)> { get set }
    var needToUpdateItem: Observable<(IndexPath,Bool)> { get set }
    var needToInsertItem: Observable<IndexPath> { get set }
    var needToRemoveItem: Observable<IndexPath> { get set }
    func viewWillAppear()
    func viewWillDisappear()
    func completeButtonPressed()
    func getListTitle() -> String
    func getTableRowCount() -> Int
    func getRowHeight(for row: Int) -> CGFloat
    func getCellParams(for row: Int) -> (NewListCellType, NewListCellParams)
    func tableFinishedUpdating()
    func deleteItemButtonPressed(in row: Int)
}

final class NewListViewModel: NewListViewModelProtocol {
    // MARK: - Public Properties
    var userInteractionEnabled: Observable<Bool> = Observable(true)
    var switchToMainView: Observable<Bool> = Observable(false)
    var needToUpdateCompleteButtonState: Observable<Bool> = Observable(false)
    var needToClosePopUp: Observable<Bool> = Observable(false)
    var popUpQuantity: Observable<Int> = Observable(nil)
    var popUpUnit: Observable<Int> = Observable(nil)
    var needToShowPopUp: Observable<(Int, Int, Units)> = Observable(nil)
    var needToUpdateItem: Observable<(IndexPath,Bool)> = Observable(nil)
    var needToInsertItem: Observable<IndexPath> = Observable(nil)
    var needToRemoveItem: Observable<IndexPath> = Observable(nil)
    
    // MARK: - Private Properties
    private let storageService: StorageServiceProtocol
    private let editList: UUID?
    private var existingListNames = Set<String>()
    private var listItems: [NewListCellParams] = []
    private var editedList: ShopList?
    
    // MARK: - Initializers
    init(storageService: StorageServiceProtocol, editList: UUID?) {
        self.storageService = storageService
        self.editList = editList
    }
    
    // MARK: - Public Methods
    func viewWillAppear() {
        setListItems()
        updateCompleteButtonState()
        self.existingListNames = storageService.getExistingListNames()
    }
    
    func viewWillDisappear() {
        if switchToMainView.value != true {
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
    
    func tableFinishedUpdating() {
        userInteractionEnabled.value = true
    }
    
    // MARK: - Actions
    func completeButtonPressed() {
        editList == nil
        ? storageService.saveNewList(list: buildNewList())
        : storageService.updateList(list: buildNewList())
        switchToMainView.value = true
    }
    
    func deleteItemButtonPressed(in row: Int) {
        listItems.remove(at: row)
        userInteractionEnabled.value = false
        needToRemoveItem.value = IndexPath(row: row, section: 0)
        updateCompleteButtonState()
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
                                   quantity: Int(item.quantity),
                                   unit: Units(rawValue: item.unit) ?? .piece,
                                   checked: item.checked
                                  )
            )
        }
        listItems.append(.init(row: listItems.count, title: .buttonAddProduct))
    }
    
    private func validateName(row: Int) {
        guard let newTitle = listItems[row].title else {
            return
        }
        
        if newTitle.isEmpty {
            listItems[row].error = .newListEmptyName
            return
            
        } else if row == 0,
                  existingListNames.contains(newTitle.lowercased()) && editedList == nil {
            listItems[row].error = .newListNameAlreadyUsed
            return
            
        } else if newTitle.replacingOccurrences(of: " ", with: "").isEmpty {
            listItems[row].error = .newListWrongName
            return
        }
        
        listItems[row].error = nil
    }
    
    private func validateList() -> Bool {
        listItems.first(where: { $0.title == nil || $0.title?.isEmpty == true || $0.error != nil}) == nil
    }
    
    private func updateCompleteButtonState() {
        if needToUpdateCompleteButtonState.value != validateList() {
            needToUpdateCompleteButtonState.value?.toggle()
        }
    }
    
    private func buildNewList() -> ShopList {
        var newListItems = [ListItem]()
        if listItems.count > 2 {
            for item in listItems[1...listItems.count - 2] {
                newListItems.append(.init(name: item.title ?? .newListItemPlaceholder,
                                          quantity: Int16(item.quantity ?? 1),
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
        let itemsCount = UserDefaults.standard.integer(forKey: "newListItemsCount")
        
        if itemsCount > 0 {
            for i in 1...itemsCount {
                listItems.append(
                    .init(row: i,
                          title: UserDefaults.standard.string(forKey: "newListItem\(i).title"),
                          quantity: UserDefaults.standard.integer(forKey: "newListItem\(i).quantity"),
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
}

// MARK: - NewListCellTitleDelegate
extension NewListViewModel: NewListCellTitleDelegate {
    func updateNewListTitle(with title: String?) {
        let oldListTitleState = listItems[0]
        listItems[0].title = title
        validateName(row: 0)
        if listItems[0].error != oldListTitleState.error {
            userInteractionEnabled.value = false
            needToUpdateItem.value = (IndexPath(row: 0, section: 0), true)
        }
        if oldListTitleState.title != listItems[0].title {
            updateCompleteButtonState()
        }
    }
}

// MARK: - NewListCellItemDelegate
extension NewListViewModel: NewListCellItemDelegate {
    func updateNewListItem(in row: Int, with title: String?) {
        let oldItemState = listItems[row]
        listItems[row].title = title
        validateName(row: row)
        if listItems[row].error != oldItemState.error {
            userInteractionEnabled.value = false
            needToUpdateItem.value = (IndexPath(row: row, section: 0), true)
        }
        if oldItemState.title != listItems[row].title {
            updateCompleteButtonState()
        }
    }
    
    func editQuantityButtonPressed(in row: Int) {
        needToShowPopUp.value = (row, listItems[row].quantity ?? 1, listItems[row].unit ?? .piece)
    }
}

// MARK: - NewListCellButtonDelegate
extension NewListViewModel: NewListCellButtonDelegate {
    func addNewItemButtonPressed() {
        listItems.insert(.init(row: listItems.count - 1,
                               quantity: 1,
                               unit: .piece
                              ), at: listItems.count - 1
        )
        userInteractionEnabled.value = false
        needToInsertItem.value = IndexPath(row: listItems.count - 2, section: 0)
        updateCompleteButtonState()
    }
}

// MARK: - PopUpVCDelegate
extension NewListViewModel: PopUpVCDelegate {
    func unitSelected(item: Int, unit: Units) {
        listItems[item].unit = unit
        needToUpdateItem.value = (IndexPath(row: item, section: 0), false)
    }
    
    func quantitySelected(item: Int, quantity: Int) {
        listItems[item].quantity = quantity
        needToUpdateItem.value = (IndexPath(row: item, section: 0), false)
    }
}
