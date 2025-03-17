import UIKit

final class SplashViewModel {
    
    // MARK: - Public Properties
    private var coordinator: Coordinator
    var switchToMainView: Observable<Bool> = Observable(nil)
    
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
    
    func animationCompleted() {
//        switchToMainView.value = true
        coordinator.showTabBarVC()
    }
}
