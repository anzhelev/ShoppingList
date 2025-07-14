import UIKit

final class WelcomeScreenVC: UIViewController {
    
    // MARK: - Private Properties
    private let viewModel: WelcomeScreenViewModelProtocol
    
    private lazy var newListCreationButton = {
        let button = UIButton()
        button.setTitle(viewModel.description, for: .normal)
        button.setTitleColor(.buttonTextPrimary, for: .normal)
        button.titleLabel?.font = .listScreenTitle
        button.backgroundColor = .buttonBgrTertiary
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initializers
    init(viewModel: WelcomeScreenViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Actions
    @objc private func buttonPressed() {
        viewModel.buttonPressed()
    }
    
    private func setStackView(with subviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 50
        return stackView
    }
    
    private func setHeaderLabel(with text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.font = .mainScreenTitle
        label.textColor = .black
        label.numberOfLines = 3
        return label
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        let stackSubviews: [UIView] = [
            setHeaderLabel(with: viewModel.header),
            UIImageView(image: UIImage(named: viewModel.image)),
            newListCreationButton
        ]
        
        let stackView = setStackView(with: stackSubviews)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25).isActive = true
        newListCreationButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
        newListCreationButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }
}
