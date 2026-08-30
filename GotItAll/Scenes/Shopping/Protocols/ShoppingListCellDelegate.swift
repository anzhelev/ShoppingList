import Foundation

protocol ShoppingListCellDelegate: AnyObject {
    func addNewItemButtonPressed()
    func checkBoxTapped(cellID: UUID)
    func editQuantityButtonPressed(cellID: UUID)
    func textFieldDidBeginEditing(cellID: UUID)
    func updateShoppingListItem(cellID: UUID, with title: String)
}
