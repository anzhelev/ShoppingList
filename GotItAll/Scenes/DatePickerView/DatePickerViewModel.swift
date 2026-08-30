import Foundation

final class DatePickerViewModel {

    // MARK: - Public Properties
    weak var delegate: DatePickerViewDelegate?
    let cancelButtonTitle: String = .buttonCancel
    let confirmButtonTitle: String = .buttonApply
    let titleLabel: String = .datePickerViewTitle

    // MARK: - Initializers
    init(delegate: DatePickerViewDelegate) {
        self.delegate = delegate
    }

    // MARK: - Public Methods
    func cancelAction() {
        delegate?.datePickerCancelButtonPressed()
    }

    func confirmAction(date: Date?) {
        guard let date else {
            return
        }
        delegate?.datePickerConfirmButtonPressed(date: date)
    }
}
