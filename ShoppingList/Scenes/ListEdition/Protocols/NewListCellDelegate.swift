import Foundation

protocol NewListCellDelegate: AnyObject {
    func updateNewListTitle(with title: String?)
    func updateNewListItem(id: UUID, with title: String?)
//    func getTextFieldEditState() -> Bool
    func textFieldDidBeginEditing(id: UUID)
    func addNewItemButtonPressed()
    func editQuantityButtonPressed(id: UUID)
}
