import UIKit

enum ShoppingListBinding {
    case showPopUp(UUID, Float, Units)
    case updateItem([IndexPath], Bool)
    case insertItem(IndexPath)
    case moveItem(IndexPath, IndexPath)
    case removeItem(IndexPath)
}
