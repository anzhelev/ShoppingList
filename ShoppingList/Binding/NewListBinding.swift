import UIKit

enum NewListBinding {
    case interactionEnabled(Bool)
    case updateCompleteButtonState
    case showPopUp(UUID, Float, Units)
    case updateItems([IndexPath], Bool)
    case insertItem(IndexPath)
    case removeItem(IndexPath)
    case reloadTable
}
