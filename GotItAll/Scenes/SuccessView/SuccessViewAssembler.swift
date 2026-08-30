import UIKit

final class SuccessViewAssembler {

    // MARK: - Public Methods
    public func build(delegate: SuccessViewDelegate) -> UIViewController {
        let viewModel = SuccessViewModel(delegate: delegate)
        let viewController = SuccessVC(viewModel: viewModel)
        return viewController
    }
}
