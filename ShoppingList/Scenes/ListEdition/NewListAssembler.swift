import UIKit

final class NewListAssembler {
    private let storageService = StorageService()
    
    public func build(editList: UUID?) -> UIViewController {
        let viewModel = NewListViewModel(
            storageService: storageService,
            editList: editList
        )
        let viewController = NewListViewController(
            viewModel: viewModel
        )
        return viewController
    }
}
