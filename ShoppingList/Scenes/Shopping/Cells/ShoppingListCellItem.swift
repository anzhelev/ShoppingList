import UIKit

protocol ShoppingListCellItemDelegate: AnyObject {
    func updateShoppingListItem(in row: Int, with title: String)
    func editQuantityButtonPressed(in row: Int)
    func checkBoxTapped(in row: Int)
    func textFieldDidBeginEditing()
}

final class ShoppingListCellItem: UITableViewCell {
    
    // MARK: - Public Properties
    static let reuseIdentifier = "shoppingListCellItem"
    weak var delegate: ShoppingListCellItemDelegate?
    
    // MARK: - Private Properties
    private var row = 1
    private var quantity = 1
    private var unit: Units = .piece
    private let maxNameleLenght = 15
    
    private let checkBoxImageView = UIImageView()
    
    private lazy var checkBoxButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(checkBoxTapped), for: .touchUpInside)
        checkBoxImageView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(checkBoxImageView)
        checkBoxImageView.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        checkBoxImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        checkBoxImageView.heightAnchor.constraint(equalToConstant: 33).isActive = true
        checkBoxImageView.widthAnchor.constraint(equalTo: checkBoxImageView.heightAnchor).isActive = true
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
    
    private lazy var addQuantityButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(editQuantity), for: .touchUpInside)
        let arrowImageView = UIImageView(image: UIImage(named: "arrowRight")?.withTintColor(.listItemRightArrow))
        [quantityLabel, arrowImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview($0)
            $0.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        }
        quantityLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor).isActive = true
        arrowImageView.leadingAnchor.constraint(equalTo: quantityLabel.trailingAnchor, constant: 10).isActive = true
        arrowImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16).isActive = true
        arrowImageView.heightAnchor.constraint(equalToConstant: 14).isActive = true
        arrowImageView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        
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
        
        let attributeString = NSMutableAttributedString(string: params.title)
        attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle,
                                     value: params.checked ? 1: 0,
                                     range: NSRange(location: 0, length: attributeString.length)
        )
        
        itemNameField.attributedText = attributeString
        itemNameField.textColor = params.checked ? .textColorSecondary : .textColorPrimary
        quantityLabel.text = "\(quantity) \(NSLocalizedString(unit.rawValue, comment: ""))"
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
        [checkBoxButton, itemNameField, addQuantityButton, separatorView, errorLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            checkBoxButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            checkBoxButton.widthAnchor.constraint(equalToConstant: 44),
            checkBoxButton.heightAnchor.constraint(equalTo: checkBoxButton.widthAnchor),
            checkBoxButton.centerYAnchor.constraint(equalTo: itemNameField.centerYAnchor),
            itemNameField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            itemNameField.leadingAnchor.constraint(equalTo: checkBoxButton.trailingAnchor, constant: 21),
            itemNameField.heightAnchor.constraint(equalToConstant: 44),
            
            addQuantityButton.widthAnchor.constraint(equalToConstant: 85),
            addQuantityButton.leadingAnchor.constraint(equalTo: itemNameField.trailingAnchor, constant: 10),
            addQuantityButton.centerYAnchor.constraint(equalTo: itemNameField.centerYAnchor),
            addQuantityButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: itemNameField.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: itemNameField.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),
            errorLabel.leadingAnchor.constraint(equalTo: itemNameField.leadingAnchor),
            errorLabel.topAnchor.constraint(equalTo: itemNameField.bottomAnchor),
            errorLabel.heightAnchor.constraint(equalToConstant: 29)
        ])
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
