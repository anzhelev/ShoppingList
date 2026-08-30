import Foundation

struct NewListCellParams {

    // MARK: - Public Properties
    var id: UUID
    var title: String?
    var quantity: Float?
    var unit: Units?
    var checked: Bool?
    var error: String?
    var startEditing: Bool?
}

enum NewListCellType {

    // MARK: - Constants
    case button
    case item
    case title
}
