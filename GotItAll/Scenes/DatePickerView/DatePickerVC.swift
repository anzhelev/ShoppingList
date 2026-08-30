import UIKit

final class DatePickerVC: UIViewController {

    // MARK: - Private Properties
    private let datePickerView: DatePickerView

    // MARK: - Initializers
    init(viewModel: DatePickerViewModel) {
        self.datePickerView = DatePickerView(viewModel: viewModel)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    // MARK: - Private Methods
    private func setupView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.addSubview(datePickerView)

        NSLayoutConstraint.activate([
            datePickerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            datePickerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            datePickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            datePickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            datePickerView.heightAnchor.constraint(equalToConstant: 420)
        ])
    }
}
