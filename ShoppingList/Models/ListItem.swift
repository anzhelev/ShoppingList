struct ListItem {
    let name: String
    let quantity: Float
    let unit: Units.RawValue
    let checked: Bool
}

enum Units: String {
    case kg = "units.kg"
    case liter = "units.liter"
    case pack = "units.pack"
    case piece = "units.piece"
}
