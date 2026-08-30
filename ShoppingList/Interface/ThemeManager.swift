import UIKit

enum AppTheme: Int, CaseIterable {

    // MARK: - Constants
    case light
    case automatic
    case dark

    // MARK: - Public Properties
    var interfaceStyle: UIUserInterfaceStyle {
        interfaceStyle(for: Date(), calendar: .current)
    }

    // MARK: - Public Methods
    func interfaceStyle(for date: Date, calendar: Calendar) -> UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .automatic:
            let hour = calendar.component(.hour, from: date)
            return 7..<19 ~= hour ? .light : .dark
        case .dark:
            return .dark
        }
    }
}

final class ThemeManager {

    // MARK: - Public Properties
    static let themeManager = ThemeManager()

    var currentTheme: AppTheme {
        get { AppTheme(rawValue: userDefaults.integer(forKey: themeKey)) ?? .automatic }
        set { userDefaults.set(newValue.rawValue, forKey: themeKey) }
    }

    // MARK: - Private Properties
    private let themeKey = "appTheme"
    private let userDefaults = UserDefaults.standard

    // MARK: - Initializers
    private init() {
        if userDefaults.object(forKey: themeKey) == nil {
            userDefaults.set(AppTheme.automatic.rawValue, forKey: themeKey)
        }
    }

    // MARK: - Public Methods
    func applyCurrentTheme(for window: UIWindow) {
        window.overrideUserInterfaceStyle = currentTheme.interfaceStyle
    }
}
