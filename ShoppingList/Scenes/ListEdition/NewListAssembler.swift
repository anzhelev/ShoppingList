import UIKit

final class NewListAssembler {
    
    public func build(coordinator: Coordinator, editList: UUID?) -> UIViewController {
        let viewModel = NewListViewModel(
            coordinator: coordinator,
            editList: editList
        )
        let viewController = NewListViewController(
            viewModel: viewModel
        )
        return viewController
    }
}
