import Foundation

struct Language {

    // MARK: - Public Properties
    let code: String
    let name: String
}

final class LanguageManager {

    // MARK: - Public Properties
    static let languageManager = LanguageManager()

    var currentLanguage: Int {
        get { languageCodes.firstIndex(of: savedLanguageCode) ?? 0 }
        set { saveLanguage(at: newValue) }
    }

    var languages: [Language] {
        [
            Language(code: languageCodes[0], name: localizedString(forKey: "languages.system")),
            Language(code: languageCodes[1], name: localizedString(forKey: "languages.russian")),
            Language(code: languageCodes[2], name: localizedString(forKey: "languages.english"))
        ]
    }

    // MARK: - Private Properties
    private let appleLanguagesKey = "AppleLanguages"
    private let languageCodes = ["system", "ru", "en"]
    private let selectedLanguageKey = "selectedLanguageCode"
    private let userDefaults = UserDefaults.standard

    private var savedLanguageCode: String {
        let code = userDefaults.string(forKey: selectedLanguageKey) ?? languageCodes[0]
        return languageCodes.contains(code) ? code : languageCodes[0]
    }

    // MARK: - Initializers
    private init() {
        migrateLegacyLanguageIfNeeded()
    }

    // MARK: - Public Methods
    func localizedString(forKey key: String) -> String {
        guard savedLanguageCode != languageCodes[0],
              let path = Bundle.main.path(forResource: savedLanguageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        }

        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    // MARK: - Private Methods
    private func migrateLegacyLanguageIfNeeded() {
        if userDefaults.string(forKey: selectedLanguageKey) == nil {
            let legacyCode = userDefaults.stringArray(forKey: appleLanguagesKey)?.first
            let selectedCode = legacyCode.flatMap { languageCodes.contains($0) ? $0 : nil } ?? languageCodes[0]
            userDefaults.set(selectedCode, forKey: selectedLanguageKey)
        }

        userDefaults.removeObject(forKey: appleLanguagesKey)
    }

    private func saveLanguage(at index: Int) {
        guard languageCodes.indices.contains(index) else {
            return
        }

        userDefaults.set(languageCodes[index], forKey: selectedLanguageKey)
        userDefaults.removeObject(forKey: appleLanguagesKey)
    }
}
