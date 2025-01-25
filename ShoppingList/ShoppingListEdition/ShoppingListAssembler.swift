import UIKit

final class ShoppingListAssembler {
    private let storageService = StorageService()
    
    public func build(listInfo: ListInfo) -> UIViewController {
        let viewModel = ShoppingListViewModel(listInfo: listInfo, storageService: storageService)
        let viewController = ShoppingListViewController(
            viewModel: viewModel
        )
        return viewController
    }
}
