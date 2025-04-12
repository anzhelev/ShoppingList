import Foundation

protocol PopUpVCDelegate: AnyObject {
    func unitSelected(itemID: UUID, unit: Units)
    func quantitySelected(itemID: UUID, quantity: Float)
}
