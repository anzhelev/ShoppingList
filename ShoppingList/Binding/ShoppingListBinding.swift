import UIKit

enum ShoppingListBinding {

    // MARK: - Constants
    case insertItem(IndexPath)
    case moveItem(IndexPath, IndexPath)
    case reloadTable
    case removeItem(IndexPath)
    case showPopUp(UUID, Float, Units)
    case updateBottomButton(Bool)
    case updateCheckAllAvailability(Bool)
    case updateCheckAllSwitch(Bool)
    case updateItems([IndexPath], Bool)
}
