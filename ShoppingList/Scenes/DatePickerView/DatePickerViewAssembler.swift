import UIKit

final class DatePickerViewAssembler {
 
    public func build(delegate: DatePickerViewDelegate) -> UIViewController {
        let viewModel = DatePickerViewModel(delegate: delegate)
        let viewController = DatePickerVC(viewModel: viewModel)
        return viewController
    }
}

