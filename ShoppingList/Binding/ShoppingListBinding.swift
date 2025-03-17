import UIKit

enum ShoppingListBinding {
    case updateCompleteButtonState
    case switchToSuccessView(String)
    case updateButtonState
    case showPopUp(Int, Int, Units)
    case updateItem([IndexPath], Bool)
    case insertItem(IndexPath)
    case moveItem(IndexPath, IndexPath)
    case removeItem(IndexPath)
}
