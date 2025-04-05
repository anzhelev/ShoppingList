import UIKit

enum NewListBinding {
    case interactionEnabled(Bool)
    case updateCompleteButtonState
    case showPopUp(Int, Float, Units)
    case updateItems([IndexPath], Bool)
    case insertItem(IndexPath)
    case removeItem(IndexPath)
    case reloadTable
}
