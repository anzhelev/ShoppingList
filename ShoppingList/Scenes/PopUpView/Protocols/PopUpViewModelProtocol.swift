protocol PopUpViewModelProtocol {
    var popUpBinding: Observable<PopUpBinding> { get set }
    func getQuantity() -> Int
    func getUnitIndex() -> Int    
    func unitSelected(unit index: Int)
    func minusButtonPressed()
    func plusButtonPressed()
    func doneButtonPressed()
}
