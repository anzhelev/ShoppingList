protocol PopUpViewModelProtocol {
    var popUpBinding: Observable<PopUpBinding> { get set }
    func getQuantity() -> String
    func getUnitIndex() -> Int
    func unitSelected(unit index: Int)
    func minusButtonPressed(for value: String?)
    func plusButtonPressed(for value: String?)
    func doneButtonPressed()
    func quantityUpdated(with value: String?)
}
