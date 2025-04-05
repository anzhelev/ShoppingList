protocol NewListCellDelegate: AnyObject {
    func updateNewListTitle(with title: String?)
    func updateNewListItem(in row: Int, with title: String?)
//    func getTextFieldEditState() -> Bool
    func textFieldDidBeginEditing(in row: Int)
    func addNewItemButtonPressed()
    func editQuantityButtonPressed(in row: Int)
}
