import UIKit

final class SettingsAssembler {
    
    public func build(coordinator: Coordinator) -> UIViewController {
        let viewModel = SettingsViewModel(coordinator: coordinator)
        let viewController = SettingsViewController(viewModel: viewModel)
        return viewController
    }
}

