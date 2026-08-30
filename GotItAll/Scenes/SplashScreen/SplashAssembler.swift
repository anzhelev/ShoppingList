import UIKit

final class SplashAssembler {

    // MARK: - Public Methods
    public func build(coordinator: Coordinator) -> UIViewController {
        let viewModel = SplashViewModel(coordinator: coordinator)
        let viewController = SplashViewController(viewModel: viewModel)
        return viewController
    }
}
