protocol PopUpViewModelProtocol: AnyObject {
    var popUpBinding: Observable<PopUpBinding> { get set }

    func doneButtonPressed(for value: String?)
    func getQuantity() -> String
    func getUnitIndex() -> Int
    func minusButtonPressed(for value: String?)
    func plusButtonPressed(for value: String?)
    func quantityUpdated(with value: String?)
    func unitSelected(unit index: Int)
}
