final class PopUpViewModel: PopUpViewModelProtocol {
    
    // MARK: - Public Properties
    weak var delegate: PopUpVCDelegate?
    var popUpBinding: Observable<PopUpBinding> = Observable(nil)
    
    // MARK: - Private Properties
    private let item: Int
    private var quantity: Float
    private var unit: Units
    
    
    // MARK: - Initializers
    init(item: Int, delegate: PopUpVCDelegate?, quantity: Float, unit: Units) {
        self.item = item
        self.delegate = delegate
        self.quantity = quantity
        self.unit = unit
    }
    
    // MARK: - Public Methods
    func getQuantity() -> String {
        quantity.rounded(.towardZero) == quantity
        ? String(Int(quantity))
        : String(format: "%.1f", quantity)
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
    
    func minusButtonPressed(for value: String?) {
        let quantityAsFloat = Float(value ?? "") ?? 0
        
        var quantityAsString: String = ""
        
        switch unit {
        case .kg, .liter:
            quantity = (max(0.1, quantityAsFloat - 0.1) * 10).rounded(.toNearestOrAwayFromZero) / 10
            quantityAsString = quantity.rounded(.towardZero) == quantity
            ? String(Int(quantity))
            : String(format: "%.1f", quantity)
        case .pack, .piece:
            quantity = max(1, quantityAsFloat - 1).rounded(.up)
            quantityAsString = String(Int(quantity))
        }
        
        popUpBinding.value = .popUpQuantity(quantityAsString)
        delegate?.quantitySelected(item: item, quantity: quantity)
    }
    
    func plusButtonPressed(for value: String?) {
        let quantityAsFloat = Float(value ?? "") ?? 0
        
        var quantityAsString: String = ""
        
        switch unit {
        case .kg, .liter:
            quantity = (min(quantityAsFloat + 0.1, 1000) * 10).rounded(.toNearestOrAwayFromZero) / 10
            quantityAsString = quantity.rounded(.towardZero) == quantity
            ? String(Int(quantity))
            : String(format: "%.1f", quantity)
        case .pack, .piece:
            quantity = min(1000, quantityAsFloat + 1).rounded(.down)
            quantityAsString = String(Int(quantity))
        }
        
        popUpBinding.value = .popUpQuantity(quantityAsString)
        delegate?.quantitySelected(item: item, quantity: quantity)
    }
    
    func clearButtonPressed() {
        popUpBinding.value = .popUpQuantity("")
        delegate?.quantitySelected(item: item, quantity: quantity)
    }
    
    func quantityUpdated(with value: String?) {
        let quantityAsFloat = Float(value ?? "") ?? 1
        quantity = (quantityAsFloat * 10).rounded(.toNearestOrAwayFromZero) / 10
        let quantityAsString = quantity.rounded(.towardZero) == quantity
        ? String(Int(quantity))
        : String(format: "%.1f", quantity)
        
        popUpBinding.value = .popUpQuantity(quantityAsString)
        delegate?.quantitySelected(item: item, quantity: quantity)
    }
}
