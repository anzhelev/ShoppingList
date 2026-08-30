import Foundation

final class Observable<Value> {

    // MARK: - Public Properties
    var value: Value? {
        didSet {
            notifyListener()
        }
    }

    // MARK: - Private Properties
    private var listener: ((Value?) -> Void)?

    // MARK: - Initializers
    init(_ value: Value?) {
        self.value = value
    }

    // MARK: - Public Methods
    func bind(_ listener: @escaping (Value?) -> Void) {
        self.listener = listener
        performOnMain { [weak self] in
            listener(self?.value)
        }
    }

    // MARK: - Private Methods
    private func notifyListener() {
        performOnMain { [weak self] in
            guard let self else {
                return
            }
            self.listener?(self.value)
        }
    }

    private func performOnMain(_ action: @escaping () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }
}
