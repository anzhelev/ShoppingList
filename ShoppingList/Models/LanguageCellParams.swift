struct LanguageCellParams {
    let name: String
    let corners: RoundedCorners
    let separator: Bool
    var isSelected: Bool
}

enum RoundedCorners: String {
    case top
    case bottom
    case all
    case none
}
