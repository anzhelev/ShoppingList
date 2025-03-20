import Foundation

protocol SettingsViewModelProtocol {
    var settingsBinding: Observable<SettingsBinding> { get set }
    var languageStackTitle: String { get }
    var themeStackTitle: String { get }
    var themes: [String] { get }
    func getTheme() ->  Int
    func getTableRowCount() -> Int
    func getCellParams(for index: Int) -> LanguageCellParams
    func setTheme(themeIndex: Int)
    func languageSelected(_ row: Int)
}

final class SettingsViewModel: SettingsViewModelProtocol {
    
    var settingsBinding: Observable<SettingsBinding> = Observable(nil)

    // MARK: - Public Properties
    let languageStackTitle: String = .settingsLanguageSectionTitle
    let themeStackTitle: String = .settingsThemeSectionTitle
    let themes: [String] = [.themeLight, .themeAutomatic, .themeDark]
    
    // MARK: - Private Properties
    private var coordinator: Coordinator
    private var languages: [Language]
    
    // MARK: - Initializers
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
        self.languages = coordinator.getLanguages()
    }
    
    // MARK: - Public Methods
    func getTheme() ->  Int {
        coordinator.currentTheme
    }
    
    func languageSelected(_ row: Int) {
        coordinator.currentLanguage = row
        settingsBinding.value = .showAlert(.settingsAlertTitle, .settingsAlertMessage, .buttonOk)
    }
    
    func setTheme(themeIndex: Int) {
        coordinator.currentTheme = themeIndex
        coordinator.applyCurrentTheme()
    }
    
    func getTableRowCount() -> Int {
        languages.count
    }
    
    func getCellParams(for row: Int) -> LanguageCellParams {
        var corners: RoundedCorners = .none
        var separator: Bool = false
        
        if languages.count == 1 {
            corners = .all
        } else if row == 0 {
            corners = .top
            separator.toggle()
        } else if row == languages.count - 1 {
            corners = .bottom
        } else {
            separator.toggle()
        }
        
        return .init(
            name: languages[row].name,
            corners: corners,
            separator: separator,
            isSelected: coordinator.currentLanguage == row
        )
    }
}
