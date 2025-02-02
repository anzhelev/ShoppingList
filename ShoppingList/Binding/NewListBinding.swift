import UIKit

enum NewListBinding {
    case updateCompleteButtonState
    case switchToMainView
    case showPopUp(Int, Int, Units)
    case updateItem(IndexPath, Bool)
    case insertItem(IndexPath)
    case removeItem(IndexPath)
}
