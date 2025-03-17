import Foundation

struct Language {
    let name: String
    let code: String
}

class LanguageManager {
    static let languageManager = LanguageManager()
    
    var currentLanguage: String {
        get {
            getSavedLanguage()
        }
        set {
            saveLanguage(newValue)
        }
    }
    
    let languages: [Language] = [
        Language(name: "Системный", code: "system"),
        Language(name: "Русский", code: "ru"),
        Language(name: "Английский", code: "en")
    ]
    
    private let userDefaults = UserDefaults.standard
    private let key = "selectedLanguage"

    private init() { }

    func getLanguage() -> String {
        return currentLanguage
    }
    
    func setLanguage() {
            }
    
    private func getSavedLanguage() -> String {
        return userDefaults.string(forKey: key) ?? Locale.preferredLanguages.first ?? "ru"
    }
    
    private func saveLanguage(_ language: String) {
        userDefaults.set(language, forKey: key)
    }
}
