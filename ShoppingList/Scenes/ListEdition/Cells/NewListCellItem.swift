import UIKit

final class NewListCellItem: UITableViewCell {

    // MARK: - Public Properties
    static let reuseIdentifier = "newListCellItem"
    weak var delegate: NewListCellDelegate?

    // MARK: - Private Properties
    private var cellID = UUID()
    private var quantity: Float = 1
    private var unit: Units = .piece
    private let maximumNameLength = 27

    private lazy var itemNameField = {
        let textField = UITextField()
        textField.delegate = self
        textField.clearButtonMode = .always
        textField.tintColor = .textColorPrimary
        textField.textColor = .textColorPrimary
        textField.font = .itemName
        textField.placeholder = .newListItemPlaceholder
        textField.clearButtonMode = .whileEditing
        return textField
    }()

    private let quantityLabel = {
        let label = UILabel()
        label.textColor = .textColorTertiary
        label.font = .itemName
        label.textAlignment = .right
        return label
    }()

    private let arrowImageView = UIImageView(image: UIImage(named: "arrowRight")?.withTintColor(.listItemRightArrow))

    private lazy var quantityButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(editQuantity), for: .touchUpInside)
        return button
    }()

    private var separatorView = UIView()

    private let errorLabel = {
        let label = UILabel()
        label.textColor = .textColorTertiary
        label.font = .hintLabel
        label.textAlignment = .left
        label.numberOfLines = 0
        label.text = nil
        return label
    }()

    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setUIElements()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods
    func configure(with params: NewListCellParams) {
        self.cellID = params.id
        self.quantity = params.quantity ?? 1
        self.unit = params.unit ?? .piece

        itemNameField.text = params.title
        itemNameField.textColor = params.error == nil ? .textColorPrimary : .buttonBgrSecondary

        quantityLabel.text = QuantityFormatter.string(from: quantity)
            + " \(NSLocalizedString(unit.rawValue, comment: ""))"
        separatorView.backgroundColor = params.error == nil ? .tableSeparator : .buttonBgrSecondary
        errorLabel.text = params.error
        errorLabel.isHidden = params.error == nil
        if params.startEditing == true {
            DispatchQueue.main.async { [weak self] in
                self?.itemNameField.becomeFirstResponder()
            }
        }
    }

    // MARK: - Private Methods
    private func setUIElements() {
        self.backgroundColor = .screenBgrPrimary

        let quantityButtonStack = setQuantityButtonStack(subviews: [quantityLabel, arrowImageView])
        let itemStack = setItemHorizontalStack(subviews: [itemNameField, quantityButton])

        quantityButton.addSubview(quantityButtonStack)

        [itemStack, quantityButtonStack, quantityLabel, arrowImageView, separatorView, errorLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        [itemStack, separatorView, errorLabel].forEach {
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            itemStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            itemStack.heightAnchor.constraint(equalToConstant: 44),
            itemStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            itemStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            quantityButton.heightAnchor.constraint(equalTo: itemStack.heightAnchor),
            quantityButtonStack.centerYAnchor.constraint(equalTo: quantityButton.centerYAnchor),
            quantityButtonStack.leadingAnchor.constraint(equalTo: quantityButton.leadingAnchor),
            quantityButtonStack.trailingAnchor.constraint(equalTo: quantityButton.trailingAnchor),
            quantityButtonStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            arrowImageView.heightAnchor.constraint(equalToConstant: 15),
            arrowImageView.widthAnchor.constraint(equalToConstant: 8),

            separatorView.bottomAnchor.constraint(equalTo: itemStack.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: itemStack.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),

            errorLabel.leadingAnchor.constraint(equalTo: itemStack.leadingAnchor),
            errorLabel.topAnchor.constraint(equalTo: itemStack.bottomAnchor),
            errorLabel.heightAnchor.constraint(equalToConstant: 29)
        ])
    }

    private func setQuantityButtonStack(subviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.isUserInteractionEnabled = false
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 6
        return stackView
    }

    private func setItemHorizontalStack(subviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 6
        return stackView
    }

    // MARK: - Actions
    @objc func editQuantity() {
        self.delegate?.editQuantityButtonPressed(id: cellID)
    }
}

// MARK: - UITextFieldDelegate
extension NewListCellItem: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        self.delegate?.updateNewListItem(id: cellID, with: itemNameField.text)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textFieldDidBeginEditing(id: cellID)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= maximumNameLength
    }
}
