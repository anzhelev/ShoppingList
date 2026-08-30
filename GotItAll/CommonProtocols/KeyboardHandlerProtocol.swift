import UIKit

protocol KeyboardHandler: AnyObject {
    var keyboardObserverTokens: [NSObjectProtocol] { get set }
    var keyboardWillHideAction: ((Notification) -> Void)? { get set }
    var keyboardWillShowAction: ((Notification) -> Void)? { get set }

    func removeKeyboardHandling()
    func setupKeyboardHandling()
}

// MARK: - UIViewController Support
extension KeyboardHandler where Self: UIViewController {

    func removeKeyboardHandling() {
        keyboardObserverTokens.forEach(NotificationCenter.default.removeObserver)
        keyboardObserverTokens.removeAll()
    }

    func setupKeyboardHandling() {
        removeKeyboardHandling()

        let showToken = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.keyboardWillShowAction?(notification)
        }
        let hideToken = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.keyboardWillHideAction?(notification)
        }
        keyboardObserverTokens = [showToken, hideToken]
    }
}
