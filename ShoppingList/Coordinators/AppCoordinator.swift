import UIKit
protocol Coordinator {
    var storageService: StorageService { get }
    var currentTheme: Int { get set }
    var currentLanguage: Int { get set }
    
    func start()
    func applyCurrentTheme()
    func getLanguages() -> [Language]
    func showOnboarding()
    func showWelcomeScreen()
    func switchToNewListCreationView()
    func showTabBarVC()
    func switchToShoppingList(with listInfo: ListInfo)
    func switchToListEditionView(editList: UUID?)
    func showSuccessView(delegate: SuccessViewDelegate)
    func showDatePickerView(delegate: DatePickerViewDelegate)
    func dismissPopupVC()
    func popToMainView()
    func switchToMainView()
}

final class AppCoordinator: Coordinator {
    
    let storageService = StorageService()
    
    var currentTheme: Int {
        get {
            themeManager.currentTheme
        }
        set {
            themeManager.currentTheme = newValue
        }
    }
    
    var currentLanguage: Int {
        get {
            languageManager.currentLanguage
        }
        set {
            languageManager.currentLanguage = newValue
        }
    }
    
    private let languageManager = LanguageManager.languageManager
    private let themeManager = ThemeManager.themeManager
    
    private let window: UIWindow
    private let navigationController = UINavigationController()
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        applyCurrentTheme()
        let splashScreen = SplashAssembler().build(coordinator: self)
        window.rootViewController = splashScreen
        window.makeKeyAndVisible()
    }
    
    func applyCurrentTheme() {
        themeManager.applyCurrentTheme(for: window)
    }
    
    func getLanguages() -> [Language] {
        languageManager.languages
    }    
    
    func showOnboarding() {
        let onboardingViewController = OnboardingAssembler().build(coordinator: self)
        window.rootViewController = onboardingViewController
        window.makeKeyAndVisible()
    }
    
    func showWelcomeScreen() {
        let welcomeScreen = WelcomeScreenAssembler().build(coordinator: self)
        window.rootViewController = welcomeScreen
        window.makeKeyAndVisible()
    }
    
    func showTabBarVC() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        let tabBarController = TabBarController(coordinator: self)
        navigationController.pushViewController(tabBarController, animated: false)
    }
    
    func switchToNewListCreationView() {
        showTabBarVC()
        switchToListEditionView(editList: nil)
    }
    
    func switchToShoppingList(with listInfo: ListInfo) {
        navigationController.pushViewController(
            ShoppingListAssembler().build(coordinator: self, listInfo: listInfo),
            animated: true
        )
    }
    
    func switchToListEditionView(editList: UUID?) {
        setNavBarButtons()
        navigationController.pushViewController(
            NewListAssembler().build(coordinator: self, editList: editList),
            animated: true
        )
    }
    
    func showSuccessView(delegate: SuccessViewDelegate) {
        let successVC = SuccessViewAssembler().build(
            delegate: delegate
        )
        navigationController.present(successVC, animated: true, completion: nil)
    }
    
    func showDatePickerView(delegate: DatePickerViewDelegate) {
        let datePickerVC = DatePickerViewAssembler().build(
            delegate: delegate
        )
        navigationController.present(datePickerVC, animated: true, completion: nil)
    }
    
    func dismissPopupVC() {
        navigationController.dismiss(animated: true)
    }
    
    func popToMainView() {
        navigationController.popToRootViewController(animated: true)
    }
    
    func switchToMainView() {
        navigationController.viewControllers.removeLast()
    }
    
    private func setNavBarButtons () {
        let backItem = UIBarButtonItem()
        backItem.title = .buttonBack
        backItem.tintColor = .buttonBgrPrimary
        navigationController.topViewController?.navigationItem.backBarButtonItem = backItem
    }
}
