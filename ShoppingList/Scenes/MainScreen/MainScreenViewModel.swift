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
    func getStubState() -> Bool
}

final class MainScreenViewModel: MainScreenViewModelProtocol {
    
    // MARK: - Public Properties
    var mainScreenBinding: Observable<MainScreenBinding> = Observable(nil)
    
    // MARK: - Private Properties
    private let coordinator: Coordinator
    private let storageService: StorageServiceProtocol
    private let completeMode: Bool
    private var shoppingLists: [ListInfo] = []
    private var stubState: Bool = true
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = .dateFormat
        return formatter
    }()
    
    //MARK: - Initializers
    init(coordinator: Coordinator, completeMode: Bool) {
        self.coordinator = coordinator
        self.storageService = coordinator.storageService
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
              date: dateFormatter.string(from: shoppingLists[row].date),
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
        coordinator.switchToShoppingList(with: shoppingLists[row])
    }
    
    func addNewListButtonPressed() {
        coordinator.switchToListEditionView(editList: nil)
    }
    
    func editButtonPressed(in row: Int) {
        coordinator.switchToListEditionView(editList: shoppingLists[row].listId)        
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
