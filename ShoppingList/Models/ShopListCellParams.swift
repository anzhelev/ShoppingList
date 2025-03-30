struct ShopListCellParams {
    var checked: Bool
    var title: String?
    var quantity: Float
    var unit: Units
    var error: String?
}

enum ShopListCellType {
    case item
    case button
}
