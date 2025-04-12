import UIKit

final class PopUpAssembler {
    public func build(itemID: UUID, delegate: PopUpVCDelegate?, quantity: Float, unit: Units) -> UIViewController {
        let viewModel = PopUpViewModel(
            itemID: itemID,
            delegate: delegate,
            quantity: quantity,
            unit: unit
        )
        
        let viewController = PopUpVC(
            viewModel: viewModel
        )
        return viewController
    }
}
