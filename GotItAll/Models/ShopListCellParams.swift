import Foundation

struct ShopListCellParams {

    // MARK: - Public Properties
    var id: UUID
    var checked: Bool
    var title: String?
    var quantity: Float
    var unit: Units
    var error: String?
    var isEditable: Bool = true
    var startEditing: Bool = false
}

enum ShopListCellType {

    // MARK: - Constants
    case button
    case item
}
