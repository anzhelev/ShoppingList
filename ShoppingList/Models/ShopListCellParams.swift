struct ShopListCellParams {
    var checked: Bool
    var title: String?
    var quantity: Int
    var unit: Units
    var error: String?
}

enum ShopListCellType {
    case item
    case button
}
