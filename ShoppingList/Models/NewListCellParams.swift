struct NewListCellParams {
    var row: Int
    var title: String?
    var quantity: Int?
    var unit: Units?
    var checked: Bool?
    var error: String?
}

enum NewListCellType {
    case title
    case item
    case button
}
