import UIKit

final class TabBarController: UITabBarController {

    private let coordinator: Coordinator

    private let mainViewTabBarItem = UITabBarItem(
        title: .tabBarTabsMainView,
        image: UIImage(systemName: "list.bullet.clipboard"),
        tag: 0
    )

    private let arhiveViewTabBarItem = UITabBarItem(
        title: .tabBarTabsArchiveView,
        image: UIImage(systemName: "archivebox"),
        tag: 0
    )

    private let settingsTabBarItem = UITabBarItem(
        title: .tabBarTabsSettingsView,
        image: UIImage(systemName: "gear.badge"),
        tag: 0
    )

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .screenBgrPrimary
        tabBar.unselectedItemTintColor = .tabbarInactiveTabs

        setTabs()
    }

    private func setTabs() {        
        let mainScreenView = MainScreenAssembler().build(coordinator: coordinator, completeMode: false)
        mainScreenView.tabBarItem = mainViewTabBarItem
        
        let archiveView = MainScreenAssembler().build(coordinator: coordinator, completeMode: true)
        archiveView.tabBarItem = arhiveViewTabBarItem
        
        let settingsView = SettingsAssembler().build(coordinator: coordinator)
        settingsView.tabBarItem = settingsTabBarItem

        viewControllers = [mainScreenView, archiveView, settingsView]
    }
}
