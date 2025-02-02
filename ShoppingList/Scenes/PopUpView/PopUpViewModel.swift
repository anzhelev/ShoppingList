final class PopUpViewModel: PopUpViewModelProtocol {
    
    // MARK: - Public Properties
    weak var delegate: PopUpVCDelegate?
    var popUpBinding: Observable<PopUpBinding> = Observable(nil)
    
    // MARK: - Private Properties
    private let item: Int
    private var quantity: Int
    private var unit: Units
    

    // MARK: - Initializers
    init(item: Int, delegate: PopUpVCDelegate?, quantity: Int, unit: Units) {
        self.item = item
        self.delegate = delegate
        self.quantity = quantity
        self.unit = unit
    }

    // MARK: - Public Methods
    func getQuantity() -> Int {
        quantity
    }
    
    func getUnitIndex() -> Int {
        [.kg, .liter, .pack, .piece].firstIndex(of: unit) ?? 3
    }
    
    // MARK: - Actions
    func unitSelected(unit: Int) {
        let selectedUnit: Units = [.kg, .liter, .pack, .piece][unit]
        
        if self.unit != selectedUnit {
            self.unit = selectedUnit
            delegate?.unitSelected(item: item, unit: self.unit)
        }
    }
    
    func doneButtonPressed() {
        popUpBinding.value = .closePopUp
    }
    
    func minusButtonPressed() {
        if quantity > 1 {
            quantity -= 1
            popUpBinding.value = .popUpQuantity(quantity)
            delegate?.quantitySelected(item: item, quantity: quantity)
        }
    }
    
    func plusButtonPressed() {
        if quantity < 99 {
            quantity += 1
            popUpBinding.value = .popUpQuantity(quantity)
            delegate?.quantitySelected(item: item, quantity: quantity)
        }
    }
}
