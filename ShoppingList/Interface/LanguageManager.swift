import Foundation

struct Language {

    // MARK: - Public Properties
    let code: String
    let name: String
}

final class LanguageManager {

    // MARK: - Public Properties
    static let languageManager = LanguageManager()

    let languages: [Language] = [
        Language(code: "system", name: .languageSystem),
        Language(code: "ru", name: .languageRussian),
        Language(code: "en", name: .languageEnglish)
    ]

    var currentLanguage: Int {
        get { languages.firstIndex { $0.code == savedLanguageCode } ?? 0 }
        set { saveLanguage(at: newValue) }
    }

    // MARK: - Private Properties
    private let appleLanguagesKey = "AppleLanguages"
    private let selectedLanguageKey = "selectedLanguageCode"
    private let userDefaults = UserDefaults.standard

    private var savedLanguageCode: String {
        userDefaults.string(forKey: selectedLanguageKey) ?? "system"
    }

    // MARK: - Initializers
    private init() {
        guard userDefaults.string(forKey: selectedLanguageKey) == nil else {
            return
        }

        let legacyLanguage = userDefaults.stringArray(forKey: appleLanguagesKey)?.first
        let selectedCode = legacyLanguage.flatMap { code in
            languages.contains { $0.code == code } ? code : nil
        } ?? "system"
        userDefaults.set(selectedCode, forKey: selectedLanguageKey)
    }

    // MARK: - Private Methods
    private func saveLanguage(at index: Int) {
        guard languages.indices.contains(index) else {
            return
        }

        let code = languages[index].code
        userDefaults.set(code, forKey: selectedLanguageKey)

        if code == "system" {
            userDefaults.removeObject(forKey: appleLanguagesKey)
        } else {
            userDefaults.set([code], forKey: appleLanguagesKey)
        }
    }
}
