import Foundation

protocol DatePickerViewDelegate: AnyObject {
    func datePickerConfirmButtonPressed(date: Date)
    func datePickerCancelButtonPressed()
}

