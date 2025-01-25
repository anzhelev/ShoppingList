import UIKit

enum MainScreenBinding {
    case switchView(Bool,Bool)
    case showList(ListInfo)
    case editList(UUID?)
    case showStub(Bool)
    case reloadTable
    case updateItem(IndexPath)
    case removeItem(IndexPath)
}
