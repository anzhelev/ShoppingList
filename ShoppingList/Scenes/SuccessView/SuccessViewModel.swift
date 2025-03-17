import UIKit

class SuccessViewModel {
    weak var delegate: SuccessViewDelegate?
    let successImage: UIImage? = UIImage(named: "successScreenImage")
    let congratsLabel: String = .successViewCongratulations
    let additionalLabel: String = .successViewAdditional
    let confirmButtonTitle: String = .buttonSwitchToMainScreen
    let cancelButtonTitle: String = .buttonCancel
    
    init(delegate: SuccessViewDelegate) {
        self.delegate = delegate
    }
    
    func confirmAction() {
        delegate?.confirmButtonPressed()
    }
    
    func cancelAction() {
        delegate?.cancelButtonPressed()
    }
}
