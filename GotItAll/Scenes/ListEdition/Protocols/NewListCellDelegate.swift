import Foundation

protocol NewListCellDelegate: AnyObject {
    func addNewItemButtonPressed()
    func editQuantityButtonPressed(id: UUID)
    func textFieldDidBeginEditing(id: UUID)
    func updateNewListItem(id: UUID, with title: String?)
    func updateNewListTitle(with title: String?)
}
