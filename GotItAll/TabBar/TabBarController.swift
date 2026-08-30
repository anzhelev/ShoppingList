import UIKit

final class TabBarController: UITabBarController {

    // MARK: - Private Properties
    private let archiveViewTabBarItem = UITabBarItem(
        title: .tabBarTabsArchiveView,
        image: UIImage(systemName: "archivebox"),
        tag: 1
    )

    private let coordinator: Coordinator

    private let mainViewTabBarItem = UITabBarItem(
        title: .tabBarTabsMainView,
        image: UIImage(systemName: "list.bullet.clipboard"),
        tag: 0
    )

    private let settingsTabBarItem = UITabBarItem(
        title: .tabBarTabsSettingsView,
        image: UIImage(systemName: "gear.badge"),
        tag: 2
    )

    // MARK: - Initializers
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .screenBgrPrimary
        tabBar.unselectedItemTintColor = .tabbarInactiveTabs

        setTabs()
    }

    // MARK: - Private Methods
    private func setTabs() {
        let mainScreenView = MainScreenAssembler().build(coordinator: coordinator, completeMode: false)
        mainScreenView.tabBarItem = mainViewTabBarItem

        let archiveView = MainScreenAssembler().build(coordinator: coordinator, completeMode: true)
        archiveView.tabBarItem = archiveViewTabBarItem

        let settingsView = SettingsAssembler().build(coordinator: coordinator)
        settingsView.tabBarItem = settingsTabBarItem

        viewControllers = [mainScreenView, archiveView, settingsView]
    }
}
