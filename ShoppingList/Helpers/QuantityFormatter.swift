import Foundation

enum QuantityFormatter {

    // MARK: - Private Properties
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    // MARK: - Public Methods
    static func string(from value: Float) -> String {
        formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func value(from text: String?) -> Float? {
        guard let text, !text.isEmpty else {
            return nil
        }

        if let number = formatter.number(from: text) {
            return number.floatValue
        }

        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        return Float(text.replacingOccurrences(of: decimalSeparator, with: "."))
    }
}
