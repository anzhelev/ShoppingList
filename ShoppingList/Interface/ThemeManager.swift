import Foundation
import UIKit

class ThemeManager {
    static let themeManager = ThemeManager()
    
    var currentTheme: Int {
        get {
            getSavedTheme()
        }
        set {
            saveTheme(newValue)
        }
    }
    
    private let userDefaults = UserDefaults.standard
    
    private init() { }
    
    func applyCurrentTheme(for window: UIWindow) {
        window.overrideUserInterfaceStyle =
        currentTheme == 0 ? .light
        : currentTheme == 2 ? .dark
        : .unspecified
    }
    
    private func saveTheme(_ style: Int) {
        userDefaults.set(style, forKey: "appTheme")
    }
    
    private func getSavedTheme() -> Int {
        userDefaults.integer(forKey: "appTheme")
    }
}
