import UIKit

class SuccessView: UIView {
    
    private let viewModel: SuccessViewModel
    
    init(viewModel: SuccessViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func confirmButtonTapped() {
        viewModel.confirmAction()
    }
    
    @objc private func cancelButtonTapped() {
        viewModel.cancelAction()
    }
    
    private func createLabel(text: String, font: UIFont, numberOfLines: Int) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = .textColorPrimary
        label.textAlignment = .center
        label.numberOfLines = numberOfLines
        return label
    }
    
    private func createButton(title: String, cancelMode: Bool, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.buttonTextPrimary, for: .normal)
        button.backgroundColor = cancelMode ? .buttonBgrSecondary : .buttonBgrTertiary
        button.titleLabel?.font = .listScreenTitle
        button.layer.cornerRadius = 16
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func createStackView(arrangedSubviews: [UIView], spacing: CGFloat = 0) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = spacing
        return stackView
    }
    
    private func setupView() {
        backgroundColor = .successViewBgr
        layer.cornerRadius = 24
        translatesAutoresizingMaskIntoConstraints = false
        
        let logoImageView = UIImageView(image: viewModel.successImage)
        
        let labelStack = createStackView(
            arrangedSubviews: [
                createLabel(text: viewModel.congratsLabel, font: .mainScreenStub, numberOfLines: 1),
                createLabel(text: viewModel.additionalLabel, font: .itemName, numberOfLines: 3)
            ],
            spacing: 6
        )
        
        let confirmButton = createButton(
            title: viewModel.confirmButtonTitle,
            cancelMode: false,
            action: #selector(confirmButtonTapped)
        )
        
        let cancelButton = createButton(
            title: viewModel.cancelButtonTitle,
            cancelMode: true,
            action: #selector(cancelButtonTapped)
        )
        
        let buttonStack = createStackView(arrangedSubviews: [confirmButton, cancelButton], spacing: 8)
        
        let mainStackView = createStackView(arrangedSubviews: [logoImageView, labelStack, buttonStack], spacing: 10)
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            buttonStack.widthAnchor.constraint(equalTo: mainStackView.widthAnchor, multiplier: 0.8),
            confirmButton.heightAnchor.constraint(equalToConstant: 40),
            cancelButton.heightAnchor.constraint(equalTo: confirmButton.heightAnchor)
        ])
    }
}
