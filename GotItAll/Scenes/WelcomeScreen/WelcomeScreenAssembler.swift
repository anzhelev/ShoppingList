import UIKit

final class WelcomeScreenAssembler {

    // MARK: - Public Methods
    public func build(coordinator: Coordinator) -> UIViewController {
        let viewModel = WelcomeScreenViewModel(coordinator: coordinator)
        let viewController = WelcomeScreenVC(viewModel: viewModel)
        return viewController
    }
}
