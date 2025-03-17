import UIKit

final class MainScreenAssembler {

    public func build(coordinator: Coordinator,
        completeMode: Bool
    ) -> UIViewController {
        let viewModel = MainScreenViewModel(
            coordinator: coordinator,
            completeMode: completeMode
        )
        let viewController = MainScreenViewController(
            viewModel: viewModel
        )
        return viewController
    }
}
