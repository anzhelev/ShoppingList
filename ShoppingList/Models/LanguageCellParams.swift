struct LanguageCellParams {

    // MARK: - Public Properties
    let name: String
    let corners: RoundedCorners
    let separator: Bool
    var isSelected: Bool
}

enum RoundedCorners: String {

    // MARK: - Constants
    case all
    case bottom
    case none
    case top
}
