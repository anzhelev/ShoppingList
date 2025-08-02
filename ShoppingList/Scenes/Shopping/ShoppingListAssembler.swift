import UIKit

final class ShoppingListAssembler {
    public func build(coordinator: Coordinator, listInfo: ListInfo) -> UIViewController {
        let viewModel = ShoppingListViewModel(coordinator: coordinator, listInfo: listInfo)
        let viewController = ShoppingListViewController(
            viewModel: viewModel
        )
        return viewController
    }
}
