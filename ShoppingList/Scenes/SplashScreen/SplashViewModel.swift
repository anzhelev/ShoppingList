import UIKit

final class SplashViewModel {
    
    // MARK: - Public Properties
    private var coordinator: Coordinator
    var switchToMainView: Observable<Bool> = Observable(nil)
    
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
    
    func animationCompleted() {
        if UserDefaults.standard.bool(forKey: "skipOnboarding") == false {
            UserDefaults.standard.set(true, forKey: "skipOnboarding")
            coordinator.showOnboarding()
        } else {
            coordinator.showTabBarVC()
        }
    }
}
