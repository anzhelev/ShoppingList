import Foundation

protocol SettingsViewModelProtocol {
//    var settingsBinding: Observable<SettingsBinding> { get set }
    func getTheme() ->  Int
    func getCurrentLanguage() -> String
    func getTableRowCount() -> Int
    func getCellParams(for index: Int) -> LanguageCellParams
    func setTheme(themeIndex: Int)
    func languageSelected(_ row: Int)
}

final class SettingsViewModel: SettingsViewModelProtocol {

    // MARK: - Public Properties
//    var settingsBinding: Observable<SettingsBinding> = Observable(nil)

    
    // MARK: - Private Properties
    private var coordinator: Coordinator
    
    // MARK: - Initializers
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
    
    // MARK: - Public Methods
    func getTheme() ->  Int {
        coordinator.currentTheme
    }
    
    func getCurrentLanguage() -> String {
        coordinator.languageManager.currentLanguage
    }
    
    func languageSelected(_ row: Int) {
        
    }
    
    func setTheme(themeIndex: Int) {
        coordinator.currentTheme = themeIndex
        coordinator.applyCurrentTheme()
        
        coordinator.languageManager.currentLanguage = "en"
        coordinator.setLanguage()
    }
    
    func getTableRowCount() -> Int {
        coordinator.languageManager.languages.count
    }
    
    func getCellParams(for index: Int) -> Language {
        coordinator.languageManager.languages[index]
    }
    
    func getCellParams(for row: Int) -> LanguageCellParams {
        var corners: RoundedCorners = .none
        var separator: Bool = false
        
        if coordinator.languageManager.languages.count == 1 {
            corners = .all
        } else if row == 0 {
            corners = .top
            separator.toggle()
        } else if row == coordinator.languageManager.languages.count - 1 {
            corners = .bottom
        } else {
            separator.toggle()
        }
        
        return .init(
            name: self.coordinator.languageManager.languages[row].name,
            corners: corners,
            separator: separator,
            isSelected: coordinator.languageManager.languages[row].code == getCurrentLanguage())
    }
}
