import UIKit

final class SplashAssembler {
    
    public func build() -> UIViewController {
        let viewModel = SplashViewModel()
        let viewController = SplashViewController(viewModel: viewModel)
        return viewController
    }
}
