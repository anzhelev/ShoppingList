import UIKit

final class SplashViewModel {
    
    // MARK: - Public Properties
    var switchToMainView: Observable<Bool> = Observable(nil)
    
    func animationCompleted() {
        switchToMainView.value = true
    }
}
