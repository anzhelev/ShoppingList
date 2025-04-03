import UIKit

final class ShoppingListCellItem: UITableViewCell {
    
    // MARK: - Public Properties
    static let reuseIdentifier = "shoppingListCellItem"
    weak var delegate: ShoppingListCellDelegate?
    
    // MARK: - Private Properties
    private var row = 1
    private var quantity: Float = 1
    private var unit: Units = .piece
    private let maxNameleLenght = 25
    
    private let checkBoxImageView = UIImageView()
    
    private lazy var checkBoxButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(checkBoxTapped), for: .touchUpInside)
        button.addSubview(checkBoxImageView)
        return button
    }()
    
    private lazy var itemNameField = {
        let textField = UITextField()
        textField.delegate = self
        textField.clearButtonMode = .always
        textField.tintColor = .textColorPrimary
        textField.textColor = .textColorPrimary
        textField.font = .itemName
        textField.placeholder = .newListItemPlaceholder
        textField.clearButtonMode = .whileEditing
        textField.addTarget(self, action: #selector(itemUpdated), for: .editingDidEnd)
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
    func configure(for row: Int, with params: ShopListCellParams) {
        self.row = row
        self.quantity = params.quantity
        self.unit = params.unit
        
        checkBoxImageView.image = params.checked
        ? UIImage(named: "checkboxChecked")?.withTintColor(.unitSelectionBlockBgr, renderingMode: .alwaysOriginal)
        : UIImage(named: "checkboxEmpty")?.withTintColor(.textColorPrimary, renderingMode: .alwaysOriginal)
        
        let attributeString = NSMutableAttributedString(string: params.title ?? "")
        attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle,
                                     value: params.checked ? 1: 0,
                                     range: NSRange(location: 0, length: attributeString.length)
        )
        itemNameField.attributedText = attributeString
        
        itemNameField.textColor = params.checked ? .textColorSecondary : .textColorPrimary
        let quantityAsString = quantity.rounded(.towardZero) == quantity
        ? String(Int(quantity))
        : String(format: "%.1f", quantity)
        
        quantityLabel.text = quantityAsString + " \(NSLocalizedString(unit.rawValue, comment: ""))"
        separatorView.backgroundColor = params.error == nil ? .tableSeparator : .buttonBgrSecondary
        errorLabel.text = params.error
        errorLabel.isHidden = params.error == nil
    }
    
    // MARK: - IBAction
    @objc func itemUpdated() {
        self.delegate?.updateShoppingListItem(in: row, with: itemNameField.text ?? .newListItemPlaceholder)
    }
    
    @objc func editQuantity() {
        self.delegate?.editQuantityButtonPressed(in: row)
    }
    
    @objc func checkBoxTapped() {
        self.delegate?.checkBoxTapped(in: row)
    }
    
    // MARK: - Private Methods
    
    private func setUIElements() {
        self.backgroundColor = .screenBgrPrimary
        
        let quantityButtonStack = setQuantityButtonStack(subviews: [quantityLabel, arrowImageView])
        let itemStack = setItemHorizontalStack(subviews: [itemNameField, quantityButton])
        
        quantityButton.addSubview(quantityButtonStack)
        
        [checkBoxImageView, checkBoxButton, itemStack, quantityButtonStack, quantityLabel, arrowImageView, separatorView, errorLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        [checkBoxButton, itemStack, separatorView, errorLabel].forEach {
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            checkBoxButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            checkBoxButton.widthAnchor.constraint(equalToConstant: 44),
            checkBoxButton.heightAnchor.constraint(equalTo: checkBoxButton.widthAnchor),
            checkBoxButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            
            checkBoxImageView.centerXAnchor.constraint(equalTo: checkBoxButton.centerXAnchor),
            checkBoxImageView.centerYAnchor.constraint(equalTo: checkBoxButton.centerYAnchor),
            
            itemStack.centerYAnchor.constraint(equalTo: checkBoxButton.centerYAnchor),
            itemStack.leadingAnchor.constraint(equalTo: checkBoxButton.trailingAnchor, constant: 16),
            itemStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,constant: -8),
            
            quantityButton.heightAnchor.constraint(equalTo: checkBoxButton.heightAnchor),
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
        stackView.sizeToFit()
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
}

// MARK: - UITextFieldDelegate
extension ShoppingListCellItem: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= maxNameleLenght
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textFieldDidBeginEditing()
    }
}
