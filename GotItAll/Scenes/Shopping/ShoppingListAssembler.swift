import UIKit

final class ShoppingListAssembler {

    // MARK: - Public Methods
    public func build(coordinator: Coordinator, listInfo: ListInfo) -> UIViewController {
        let viewModel = ShoppingListViewModel(coordinator: coordinator, listInfo: listInfo)
        let viewController = ShoppingListViewController(
            viewModel: viewModel
        )
        return viewController
    }
}
