import Foundation

final class PopUpViewModel: PopUpViewModelProtocol {

    // MARK: - Public Properties
    var popUpBinding: Observable<PopUpBinding> = Observable(nil)
    weak var delegate: PopUpVCDelegate?

    // MARK: - Private Properties
    private let itemID: UUID
    private var quantity: Float
    private var unit: Units

    // MARK: - Initializers
    init(itemID: UUID, delegate: PopUpVCDelegate?, quantity: Float, unit: Units) {
        self.delegate = delegate
        self.itemID = itemID
        self.quantity = quantity
        self.unit = unit
    }

    // MARK: - Public Methods
    func doneButtonPressed(for value: String?) {
        updateQuantity(with: value)
        delegate?.quantitySelected(itemID: itemID, quantity: quantity)
        delegate?.unitSelected(itemID: itemID, unit: unit)
        popUpBinding.value = .closePopUp
    }

    func getQuantity() -> String {
        format(quantity)
    }

    func getUnitIndex() -> Int {
        Units.allCases.firstIndex(of: unit) ?? Units.allCases.count - 1
    }

    func minusButtonPressed(for value: String?) {
        let step = unit.allowsFraction ? Float(0.1) : 1
        quantity = max(unit.minimumQuantity, parse(value) - step)
        quantity = normalize(quantity)
        publishQuantity()
    }

    func plusButtonPressed(for value: String?) {
        let step = unit.allowsFraction ? Float(0.1) : 1
        quantity = min(1000, parse(value) + step)
        quantity = normalize(quantity)
        publishQuantity()
    }

    func quantityUpdated(with value: String?) {
        updateQuantity(with: value)
        publishQuantity()
    }

    func unitSelected(unit index: Int) {
        guard Units.allCases.indices.contains(index) else {
            return
        }

        unit = Units.allCases[index]
        quantity = normalize(max(unit.minimumQuantity, quantity))
        delegate?.unitSelected(itemID: itemID, unit: unit)
        publishQuantity()
    }

    // MARK: - Private Methods
    private func format(_ value: Float) -> String {
        QuantityFormatter.string(from: value)
    }

    private func normalize(_ value: Float) -> Float {
        let clamped = min(1000, max(unit.minimumQuantity, value))
        if unit.allowsFraction {
            return (clamped * 10).rounded(.toNearestOrAwayFromZero) / 10
        }
        return clamped.rounded(.toNearestOrAwayFromZero)
    }

    private func parse(_ value: String?) -> Float {
        QuantityFormatter.value(from: value) ?? unit.minimumQuantity
    }

    private func publishQuantity() {
        popUpBinding.value = .popUpQuantity(format(quantity))
        delegate?.quantitySelected(itemID: itemID, quantity: quantity)
    }

    private func updateQuantity(with value: String?) {
        quantity = normalize(parse(value))
    }
}
