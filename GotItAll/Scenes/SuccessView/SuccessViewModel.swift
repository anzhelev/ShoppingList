import UIKit

final class SuccessViewModel {

    // MARK: - Public Properties
    let additionalLabel: String = .successViewAdditional
    let cancelButtonTitle: String = .buttonCancel
    let confirmButtonTitle: String = .buttonSwitchToMainScreen
    let congratsLabel: String = .successViewCongratulations
    let successImage: UIImage? = UIImage(named: "launchScreenImage")

    // MARK: - Private Properties
    private weak var delegate: SuccessViewDelegate?

    // MARK: - Initializers
    init(delegate: SuccessViewDelegate) {
        self.delegate = delegate
    }

    // MARK: - Public Methods
    func cancelAction() {
        delegate?.cancelButtonPressed()
    }

    func confirmAction() {
        delegate?.confirmButtonPressed()
    }
}
