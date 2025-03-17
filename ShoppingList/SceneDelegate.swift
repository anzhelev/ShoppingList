import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        
//        switch UserDefaults.standard.integer(forKey: "appTheme") {
//        case 1:
//            window.overrideUserInterfaceStyle = .light
//        case 2:
//            window.overrideUserInterfaceStyle = .dark
//        default:
//            window.overrideUserInterfaceStyle = .unspecified
//        }
        
        self.window = window
        let coordinator = AppCoordinator(window: window)
        coordinator.start()
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}
