import UIKit

final class SuccessAssembler {
 
    public func build(for listName: String) -> UIViewController {
        let viewModel = SuccessViewModel(listName: listName)
        let viewController = SuccessViewController(viewModel: viewModel)
        return viewController
    }
}
