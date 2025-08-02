import UIKit

enum ShoppingListBinding {
    case showPopUp(UUID, Float, Units)
    case addReminder
    case updateItem([IndexPath], Bool)
    case insertItem(IndexPath)
    case moveItem(IndexPath, IndexPath)
    case removeItem(IndexPath)
}
