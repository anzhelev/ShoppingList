import Foundation

protocol PopUpVCDelegate: AnyObject {
    func quantitySelected(itemID: UUID, quantity: Float)
    func unitSelected(itemID: UUID, unit: Units)
}
