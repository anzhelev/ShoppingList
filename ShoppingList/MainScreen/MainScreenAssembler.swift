import UIKit

final class MainScreenAssembler {
    private let storageService = StorageService()
    
    public func build(
        completeMode: Bool
    ) -> UIViewController {
        let viewModel = MainScreenViewModel(
            storageService: storageService,
            completeMode: completeMode
        )
        let viewController = MainScreenViewController(
            viewModel: viewModel
        )
        return viewController
    }
}
