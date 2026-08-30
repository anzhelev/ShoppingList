import Foundation

protocol DatePickerViewDelegate: AnyObject {
    func datePickerCancelButtonPressed()
    func datePickerConfirmButtonPressed(date: Date)
}
