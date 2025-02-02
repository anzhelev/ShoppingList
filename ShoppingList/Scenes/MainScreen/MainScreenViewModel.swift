import Foundation

protocol MainScreenViewModelProtocol {
    var mainScreenBinding: Observable<MainScreenBinding> { get set }
    func viewWillAppear()
    func getScreenTitle() -> String
    func getSwipeHintText() -> String
    func addNewListButtonPressed()
    func getTableRowCount() -> Int
    func listSelected(row: Int)
    func getCellParams(for row: Int) -> MainScreenTableCellParams
    func primaryActionButtonPressed(in row: Int)
    func editButtonPressed(in row: Int)
    func deleteListButtonPressed(in row: Int)
    func getPrimaryButtonTitle(for row: Int) -> String
    func screenSwipePerformed(reversed: Bool)
    func getStubState() -> Bool
}

final class MainScreenViewModel: MainScreenViewModelProtocol {
    
    // MARK: - Public Properties
    var mainScreenBinding: Observable<MainScreenBinding> = Observable(nil)
    
    // MARK: - Private Properties
    private let storageService: StorageServiceProtocol
    private let completeMode: Bool
    private var shoppingLists: [ListInfo] = []
    private var stubState: Bool = true
    
    //MARK: - Initializers
    init(storageService: StorageServiceProtocol, completeMode: Bool) {
        self.storageService = storageService
        self.completeMode = completeMode
    }
    
    // MARK: - Public Methods
    func viewWillAppear() {
        loadLists()
        updateStubState()
    }
    
    func getScreenTitle() -> String {
        completeMode ? .mainScreenCompletedTitle : .mainScreenActiveTitle
    }
    
    func getSwipeHintText() -> String {
        completeMode ? .mainScreenCompletedSwipeHint : .mainScreenActiveSwipeHint
    }
    
    func getTableRowCount() -> Int {
        shoppingLists.count
    }
    
    func getPrimaryButtonTitle(for row: Int) -> String {
        completeMode
        ? .buttonRestore
        : shoppingLists[row].pinned ? .buttonUnpin : .buttonPin
    }
    
    func getCellParams(for row: Int) -> MainScreenTableCellParams {
        .init(title: shoppingLists[row].title,
              separator: row == self.shoppingLists.count - 1 ? false : true,
              pinned: completeMode ? false : shoppingLists[row].pinned,
              completeMode: completeMode
        )
    }
    
    func getStubState() -> Bool {
        stubState
    }
    
    // MARK: - Actions
    func listSelected(row: Int) {
        mainScreenBinding.value = .showList(shoppingLists[row])
    }
    
    func addNewListButtonPressed() {
        mainScreenBinding.value = .editList(nil)
    }
    
    func editButtonPressed(in row: Int) {
        mainScreenBinding.value = .editList(shoppingLists[row].listId)
    }
    
    func screenSwipePerformed(reversed: Bool) {
        mainScreenBinding.value = .switchView(!completeMode, reversed)
    }
    
    func primaryActionButtonPressed(in row: Int) {
        completeMode
        ? restoreList(in: row)
        : listPinStatusToggle(in: row)
    }
    
    func deleteListButtonPressed(in row: Int) {
        storageService.deleteList(with: shoppingLists[row].listId)
        shoppingLists.remove(at: row)
        mainScreenBinding.value = .removeItem(.init(row: row, section: 0))
        updateStubState()
    }
    
    // MARK: - Private Methods
    private func loadLists() {
        shoppingLists = storageService.getListsWithStatus(isCompleted: completeMode)
        sortList()
        mainScreenBinding.value = .reloadTable
    }
    
    private func listPinStatusToggle(in row: Int) {
        shoppingLists[row].togglePinned()
        storageService.updateListInfo(listInfo: shoppingLists[row])
        sortList()
        mainScreenBinding.value = .reloadTable
    }
    
    private func restoreList(in row: Int) {
        storageService.restoreList(with: shoppingLists[row].listId)
        shoppingLists.remove(at: row)
        mainScreenBinding.value = .removeItem(.init(row: row, section: 0))
    }
    
    private func updateStubState() {
        stubState = completeMode
        ? shoppingLists.count + storageService
            .getListsWithStatus(
                isCompleted: false
            ).count == 0
        : shoppingLists.isEmpty
    }
    
    private func sortList() {
        shoppingLists.sort(by: {$0.pinned && !$1.pinned})
    }
}
