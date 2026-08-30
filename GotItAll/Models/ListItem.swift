struct ListItem {

    // MARK: - Public Properties
    let name: String
    let quantity: Float
    let unit: Units.RawValue
    let checked: Bool
}

enum Units: String, CaseIterable {

    // MARK: - Constants
    case kg = "units.kg"
    case liter = "units.liter"
    case pack = "units.pack"
    case piece = "units.piece"

    // MARK: - Public Properties
    var allowsFraction: Bool {
        self == .kg || self == .liter
    }

    var localizedName: String {
        LanguageManager.languageManager.localizedString(forKey: rawValue)
    }

    var minimumQuantity: Float {
        allowsFraction ? 0.1 : 1
    }
}
