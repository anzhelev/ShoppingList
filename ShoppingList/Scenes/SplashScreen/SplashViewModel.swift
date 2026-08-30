import UIKit

final class SplashViewModel {

    // MARK: - Private Properties
    private let coordinator: Coordinator

    // MARK: - Initializers
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Public Methods
    func animationCompleted() {
        let defaults = UserDefaults.standard
        let didCompleteOnboarding = defaults.bool(forKey: "didCompleteOnboarding")
            || defaults.bool(forKey: "skipOnboarding")

        if didCompleteOnboarding == false {
            coordinator.showOnboarding()
        } else {
            defaults.set(true, forKey: "didCompleteOnboarding")
            defaults.removeObject(forKey: "skipOnboarding")
            coordinator.showTabBarVC()
        }
    }
}
