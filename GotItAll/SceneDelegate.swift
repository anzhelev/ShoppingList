import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // MARK: - Public Properties
    var window: UIWindow?

    // MARK: - Private Properties
    private var appCoordinator: AppCoordinator?

    // MARK: - Lifecycle
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }
        let window = UIWindow(windowScene: windowScene)

        self.window = window
        appCoordinator = AppCoordinator(window: window)
        appCoordinator?.start()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        do {
            try (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        } catch {
            debugPrint("@@@ Core Data save failed: \(error.localizedDescription)")
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        appCoordinator?.applyCurrentTheme()
    }
}
