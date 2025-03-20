import Foundation

struct Language {
    let name: String
    let code: String
}

class LanguageManager {
    static let languageManager = LanguageManager()
    
    var currentLanguage: Int {
        get {
            getSavedLanguage()
        }
        set {
            saveLanguage(newValue)
        }
    }
    
    let languages: [Language] = [
        Language(name: .languageSystem, code: "system"),
        Language(name: .languageRussian, code: "ru"),
        Language(name: .languageEnglish, code: "en")
    ]
    
    private let userDefaults = UserDefaults.standard
    private let key = "AppleLanguages"
    
    private init() { }
    
    private func getSavedLanguage() -> Int {
        let storedLanguageCode = userDefaults.string(forKey: key) ?? Locale.preferredLanguages.first ?? "system"
        return languages.firstIndex(where: { $0.code == storedLanguageCode}) ?? 0
    }
    
    private func saveLanguage(_ language: Int) {
        userDefaults.set([languages[language].code], forKey: key)
        userDefaults.synchronize()
    }
}
