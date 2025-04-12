import Foundation

protocol ShoppingListCellDelegate: AnyObject {
    func updateShoppingListItem(cellID: UUID, with title: String)
    func editQuantityButtonPressed(cellID: UUID)
    func checkBoxTapped(cellID: UUID)
    func textFieldDidBeginEditing()
    func addNewItemButtonPressed()
}
