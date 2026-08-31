import Foundation

protocol MainScreenViewModelProtocol: AnyObject {
    var completeMode: Bool { get }
    var mainScreenBinding: Observable<MainScreenBinding> { get set }

    func addNewListButtonPressed()
    func clearArchiveButtonPressed()
    func deleteListButtonPressed(in row: Int)
    func editButtonPressed(in row: Int)
    func getCellParams(for row: Int) -> MainScreenTableCellParams
    func getClearArchiveButtonState() -> Bool
    func getPrimaryButtonTitle(for row: Int) -> String
    func getScreenTitle() -> String
    func getTableRowCount() -> Int
    func listSelected(row: Int)
    func primaryActionButtonPressed(in row: Int)
    func viewWillAppear()
}

final class MainScreenViewModel: MainScreenViewModelProtocol {

    // MARK: - Public Properties
    let completeMode: Bool
    var mainScreenBinding: Observable<MainScreenBinding> = Observable(nil)

    // MARK: - Private Properties
    private let coordinator: Coordinator
    private let notificationService: NotificationServiceProtocol
    private let storageService: StorageServiceProtocol
    private var shoppingLists: [ListInfo] = []

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMd")
        return formatter
    }()

    // MARK: - Initializers
    init(coordinator: Coordinator, completeMode: Bool) {
        self.completeMode = completeMode
        self.coordinator = coordinator
        notificationService = coordinator.notificationService
        storageService = coordinator.storageService
    }

    // MARK: - Public Methods
    func addNewListButtonPressed() {
        coordinator.switchToListEditionView(editList: nil)
    }

    func clearArchiveButtonPressed() {
        let listIDs = shoppingLists.map(\.listId)

        do {
            try storageService.deleteLists(with: listIDs)
            listIDs.forEach { notificationService.cancelNotification(for: $0) }
            let indexPaths = shoppingLists.indices.map { IndexPath(row: $0, section: 0) }
            shoppingLists.removeAll()
            mainScreenBinding.value = .removeItems(indexPaths)
        } catch {
            show(error)
        }
    }

    func deleteListButtonPressed(in row: Int) {
        guard shoppingLists.indices.contains(row) else {
            return
        }

        let listID = shoppingLists[row].listId
        do {
            try storageService.deleteList(with: listID)
            notificationService.cancelNotification(for: listID)
            shoppingLists.remove(at: row)
            mainScreenBinding.value = .removeItems([IndexPath(row: row, section: 0)])
        } catch {
            show(error)
        }
    }

    func editButtonPressed(in row: Int) {
        guard shoppingLists.indices.contains(row) else {
            return
        }

        coordinator.switchToListEditionView(editList: shoppingLists[row].listId)
    }

    func getCellParams(for row: Int) -> MainScreenTableCellParams {
        let list = shoppingLists[row]
        return MainScreenTableCellParams(
            title: list.title,
            date: dateFormatter.string(from: list.date),
            separator: row < shoppingLists.count - 1,
            pinned: !completeMode && list.pinned,
            completeMode: completeMode
        )
    }

    func getClearArchiveButtonState() -> Bool {
        completeMode && !shoppingLists.isEmpty
    }

    func getPrimaryButtonTitle(for row: Int) -> String {
        guard shoppingLists.indices.contains(row) else {
            return ""
        }

        if completeMode {
            return .buttonRestore
        }
        return shoppingLists[row].pinned ? .buttonUnpin : .buttonPin
    }

    func getScreenTitle() -> String {
        completeMode ? .mainScreenCompletedTitle : .mainScreenActiveTitle
    }

    func getTableRowCount() -> Int {
        shoppingLists.count
    }

    func listSelected(row: Int) {
        guard shoppingLists.indices.contains(row) else {
            return
        }

        coordinator.switchToShoppingList(with: shoppingLists[row])
    }

    func primaryActionButtonPressed(in row: Int) {
        guard shoppingLists.indices.contains(row) else {
            return
        }

        if completeMode {
            restoreList(in: row)
        } else {
            togglePinnedState(in: row)
        }
    }

    func viewWillAppear() {
        loadLists()
    }

    // MARK: - Private Methods
    private func loadLists() {
        do {
            shoppingLists = try storageService.getListsWithStatus(isCompleted: completeMode)
            mainScreenBinding.value = .reloadTable
        } catch {
            show(error)
        }
    }

    private func restoreList(in row: Int) {
        let listID = shoppingLists[row].listId
        do {
            notificationService.cancelNotification(for: listID)
            try storageService.restoreList(with: listID)
            shoppingLists.remove(at: row)
            mainScreenBinding.value = .removeItems([IndexPath(row: row, section: 0)])
        } catch {
            show(error)
        }
    }

    private func show(_ error: Error) {
        coordinator.showAlert(title: .errorTitle, message: error.localizedDescription)
    }

    private func togglePinnedState(in row: Int) {
        shoppingLists[row].togglePinned()

        do {
            try storageService.updateListInfo(listInfo: shoppingLists[row])
            shoppingLists.sort {
                if $0.pinned != $1.pinned {
                    return $0.pinned && !$1.pinned
                }
                return $0.date > $1.date
            }
            mainScreenBinding.value = .reloadTable
        } catch {
            shoppingLists[row].togglePinned()
            show(error)
        }
    }
}
