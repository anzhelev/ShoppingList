import UIKit

enum ShoppingListBinding {
    case showPopUp(Int, Float, Units)
    case updateItem([IndexPath], Bool)
    case insertItem(IndexPath)
    case moveItem(IndexPath, IndexPath)
    case removeItem(IndexPath)
}
