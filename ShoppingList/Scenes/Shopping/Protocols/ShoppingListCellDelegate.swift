protocol ShoppingListCellDelegate: AnyObject {
    func updateShoppingListItem(in row: Int, with title: String)
    func editQuantityButtonPressed(in row: Int)
    func checkBoxTapped(in row: Int)
    func textFieldDidBeginEditing()
    func addNewItemButtonPressed()
}
