import UIKit

final class SettingsAssembler {

    // MARK: - Public Methods
    public func build(coordinator: Coordinator) -> UIViewController {
        let viewModel = SettingsViewModel(coordinator: coordinator)
        let viewController = SettingsViewController(viewModel: viewModel)
        return viewController
    }
}
