import UIKit

final class SuccessViewAssembler {
 
    public func build(delegate: SuccessViewDelegate) -> UIViewController {
        let viewModel = SuccessViewModel(delegate: delegate)
        let viewController = SuccessVC(viewModel: viewModel)
        return viewController
    }
}
