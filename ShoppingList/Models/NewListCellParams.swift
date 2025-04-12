import Foundation

struct NewListCellParams {
    var id: UUID
    var title: String?
    var quantity: Float?
    var unit: Units?
    var checked: Bool?
    var error: String?
    var startEditing: Bool?
}

enum NewListCellType {
    case title
    case item
    case button
}
