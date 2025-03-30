import UIKit

enum NewListBinding {
    case updateCompleteButtonState
    case showPopUp(Int, Float, Units)
    case updateItem(IndexPath, Bool)
    case insertItem(IndexPath)
    case removeItem(IndexPath)
}
