import Foundation

protocol SettingsViewModelProtocol {
    var languageStackTitle: String { get }
    var settingsBinding: Observable<SettingsBinding> { get set }
    var themeStackTitle: String { get }
    var themes: [String] { get }

    func getCellParams(for index: Int) -> LanguageCellParams
    func getTableRowCount() -> Int
    func getTheme() -> Int
    func languageSelected(_ row: Int)
    func setTheme(themeIndex: Int)
}

final class SettingsViewModel: SettingsViewModelProtocol {

    // MARK: - Public Properties
    let languageStackTitle: String = .settingsLanguageSectionTitle
    var settingsBinding: Observable<SettingsBinding> = Observable(nil)
    let themeStackTitle: String = .settingsThemeSectionTitle
    let themes: [String] = [.themeLight, .themeAutomatic, .themeDark]

    // MARK: - Private Properties
    private let coordinator: Coordinator
    private let languages: [Language]

    // MARK: - Initializers
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
        self.languages = coordinator.getLanguages()
    }

    // MARK: - Public Methods
    func getCellParams(for row: Int) -> LanguageCellParams {
        var corners: RoundedCorners = .none
        var separator = false

        if languages.count == 1 {
            corners = .all
        } else if row == 0 {
            corners = .top
            separator = true
        } else if row == languages.count - 1 {
            corners = .bottom
        } else {
            separator = true
        }

        return LanguageCellParams(
            name: languages[row].name,
            corners: corners,
            separator: separator,
            isSelected: coordinator.currentLanguage == row
        )
    }

    func getTableRowCount() -> Int {
        languages.count
    }

    func getTheme() -> Int {
        coordinator.currentTheme.rawValue
    }

    func languageSelected(_ row: Int) {
        coordinator.currentLanguage = row
        settingsBinding.value = .showAlert(.settingsAlertTitle, .settingsAlertMessage, .buttonOk)
    }

    func setTheme(themeIndex: Int) {
        guard let theme = AppTheme(rawValue: themeIndex) else {
            return
        }

        coordinator.currentTheme = theme
        coordinator.applyCurrentTheme()
    }
}
