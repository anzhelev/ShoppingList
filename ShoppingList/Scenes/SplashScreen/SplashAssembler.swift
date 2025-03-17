import UIKit

final class SplashAssembler {
    
    public func build(coordinator: Coordinator) -> UIViewController {
        let viewModel = SplashViewModel(coordinator: coordinator)
        let viewController = SplashViewController(viewModel: viewModel)
        return viewController
    }
}
