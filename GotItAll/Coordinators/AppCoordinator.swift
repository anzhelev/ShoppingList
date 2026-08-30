import UIKit

protocol Coordinator: AnyObject {
    var currentLanguage: Int { get set }
    var currentTheme: AppTheme { get set }
    var notificationService: NotificationServiceProtocol { get }
    var storageService: StorageServiceProtocol { get }

    func applyCurrentTheme()
    func dismissPopupVC(completion: (() -> Void)?)
    func getLanguages() -> [Language]
    func popToMainView()
    func showAlert(title: String, message: String)
    func showDatePickerView(delegate: DatePickerViewDelegate)
    func showOnboarding()
    func showNotificationPermissionAlert()
    func showSuccessView(delegate: SuccessViewDelegate)
    func showTabBarVC()
    func showWelcomeScreen()
    func start()
    func switchToListEditionView(editList: UUID?)
    func switchToMainView()
    func switchToNewListCreationView()
    func switchToShoppingList(with listInfo: ListInfo)
}

extension Coordinator {

    func dismissPopupVC() {
        dismissPopupVC(completion: nil)
    }
}

final class AppCoordinator: Coordinator {

    // MARK: - Public Properties
    let notificationService: NotificationServiceProtocol
    let storageService: StorageServiceProtocol

    var currentLanguage: Int {
        get { languageManager.currentLanguage }
        set { languageManager.currentLanguage = newValue }
    }

    var currentTheme: AppTheme {
        get { themeManager.currentTheme }
        set { themeManager.currentTheme = newValue }
    }

    // MARK: - Private Properties
    private let languageManager = LanguageManager.languageManager
    private let navigationController = UINavigationController()
    private let themeManager = ThemeManager.themeManager
    private let window: UIWindow

    // MARK: - Initializers
    init(
        window: UIWindow,
        storageService: StorageServiceProtocol = StorageService(),
        notificationService: NotificationServiceProtocol = NotificationService()
    ) {
        self.window = window
        self.storageService = storageService
        self.notificationService = notificationService
    }

    // MARK: - Public Methods
    func applyCurrentTheme() {
        themeManager.applyCurrentTheme(for: window)
    }

    func dismissPopupVC(completion: (() -> Void)?) {
        navigationController.dismiss(animated: true, completion: completion)
    }

    func getLanguages() -> [Language] {
        languageManager.languages
    }

    func popToMainView() {
        navigationController.popToRootViewController(animated: true)
    }

    func showAlert(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: .buttonOk, style: .default))
            let presenter = self.navigationController.presentedViewController
                ?? self.navigationController.visibleViewController
                ?? self.window.rootViewController
            presenter?.present(alert, animated: true)
        }
    }

    func showDatePickerView(delegate: DatePickerViewDelegate) {
        let viewController = DatePickerViewAssembler().build(delegate: delegate)
        navigationController.present(viewController, animated: true)
    }

    func showOnboarding() {
        window.rootViewController = OnboardingAssembler().build(coordinator: self)
        window.makeKeyAndVisible()
    }

    func showNotificationPermissionAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            let alert = UIAlertController(
                title: .errorTitle,
                message: .notificationPermissionDenied,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: .buttonCancel, style: .cancel))
            alert.addAction(
                UIAlertAction(title: .buttonSettings, style: .default) { _ in
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    UIApplication.shared.open(settingsURL)
                }
            )
            let presenter = self.navigationController.presentedViewController
                ?? self.navigationController.visibleViewController
                ?? self.window.rootViewController
            presenter?.present(alert, animated: true)
        }
    }

    func showSuccessView(delegate: SuccessViewDelegate) {
        let viewController = SuccessViewAssembler().build(delegate: delegate)
        navigationController.present(viewController, animated: true)
    }

    func showTabBarVC() {
        navigationController.setViewControllers([TabBarController(coordinator: self)], animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func showWelcomeScreen() {
        window.rootViewController = WelcomeScreenAssembler().build(coordinator: self)
        window.makeKeyAndVisible()
    }

    func start() {
        applyCurrentTheme()
        window.rootViewController = SplashAssembler().build(coordinator: self)
        window.makeKeyAndVisible()

        if let error = AppDelegate.appDelegate?.persistentStoreError {
            showAlert(title: .errorTitle, message: error.localizedDescription)
        }
    }

    func switchToListEditionView(editList: UUID?) {
        setNavigationBackButton()
        let viewController = NewListAssembler().build(coordinator: self, editList: editList)
        navigationController.pushViewController(viewController, animated: true)
    }

    func switchToMainView() {
        guard navigationController.viewControllers.count > 1 else {
            return
        }

        navigationController.popViewController(animated: true)
    }

    func switchToNewListCreationView() {
        showTabBarVC()
        switchToListEditionView(editList: nil)
    }

    func switchToShoppingList(with listInfo: ListInfo) {
        let viewController = ShoppingListAssembler().build(coordinator: self, listInfo: listInfo)
        navigationController.pushViewController(viewController, animated: true)
    }

    // MARK: - Private Methods
    private func setNavigationBackButton() {
        let backItem = UIBarButtonItem()
        backItem.tintColor = .buttonBgrPrimary
        backItem.title = .buttonBack
        navigationController.topViewController?.navigationItem.backBarButtonItem = backItem
    }
}
