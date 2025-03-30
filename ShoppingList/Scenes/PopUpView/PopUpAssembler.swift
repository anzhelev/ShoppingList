import UIKit

final class PopUpAssembler {
    public func build(item: Int, delegate: PopUpVCDelegate?, quantity: Float, unit: Units) -> UIViewController {
        let viewModel = PopUpViewModel(
            item: item,
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
