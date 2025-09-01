import UIKit

class DatePickerViewModel {
    weak var delegate: DatePickerViewDelegate?
    let titleLabel: String = .datePickerViewTitle
    let confirmButtonTitle: String = .buttonApply
    let cancelButtonTitle: String = .buttonCancel
    
    init(delegate: DatePickerViewDelegate) {
        self.delegate = delegate
    }
    
    func confirmAction(date: Date?) {
        guard let date else {
            return
        }
        delegate?.datePickerConfirmButtonPressed(date: date)
    }
    
    func cancelAction() {
        delegate?.datePickerCancelButtonPressed()
    }
}
