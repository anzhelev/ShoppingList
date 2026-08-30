import UIKit

enum NewListBinding {

    // MARK: - Constants
    case insertItem(IndexPath)
    case interactionEnabled(Bool)
    case reloadTable
    case removeItem(IndexPath)
    case showPopUp(UUID, Float, Units)
    case updateCompleteButtonState
    case updateItems([IndexPath], Bool)
}
