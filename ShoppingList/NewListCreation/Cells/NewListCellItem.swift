import UIKit

protocol NewListCellItemDelegate: AnyObject {
    func updateNewListItem(in row: Int, with title: String?, quantity: Int, unit: Units)
    func editQuantityButtonPressed(in row: Int)
}

final class NewListCellItem: UITableViewCell {
    
    // MARK: - Public Properties
    static let reuseIdentifier = "newListCellItem"
    weak var delegate: NewListCellItemDelegate?
    
    // MARK: - Private Properties
    private var row = 1
    private var quantity = 1
    private var unit: Units = .piece
    private let maxNameleLenght = 15
    
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
        arrowImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor).isActive = true
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let margins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        contentView.frame = contentView.frame.inset(by: margins)
    }
    
    // MARK: - Public Methods
    func configure(with params: NewListCellParams) {
        self.row = params.row
        self.quantity = params.quantity ?? 1
        self.unit = params.unit ?? .piece
        
        itemNameField.text = params.title
        itemNameField.textColor = params.error == nil ? .textColorPrimary : .buttonBgrSecondary
        quantityLabel.text = "\(quantity) \(NSLocalizedString(unit.rawValue, comment: ""))"
        separatorView.backgroundColor = params.error == nil ? .tableSeparator : .buttonBgrSecondary
        errorLabel.text = params.error
        errorLabel.isHidden = params.error == nil
    }
    
    // MARK: - IBAction
    @objc func itemUpdated() {
        self.delegate?.updateNewListItem(in: row, with: itemNameField.text, quantity: quantity, unit: unit)
    }
    
    @objc func editQuantity() {
        self.delegate?.editQuantityButtonPressed(in: row)
        
    }
    
    // MARK: - Private Methods
    private func setUIElements() {
        self.backgroundColor = .screenBgrPrimary
        [itemNameField, addQuantityButton, separatorView, errorLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            itemNameField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            itemNameField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            itemNameField.heightAnchor.constraint(equalToConstant: 44),
            addQuantityButton.widthAnchor.constraint(equalToConstant: 85),
            addQuantityButton.leadingAnchor.constraint(equalTo: itemNameField.trailingAnchor, constant: 10),
            addQuantityButton.centerYAnchor.constraint(equalTo: itemNameField.centerYAnchor),
            addQuantityButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separatorView.bottomAnchor.constraint(equalTo: itemNameField.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            errorLabel.topAnchor.constraint(equalTo: itemNameField.bottomAnchor),
            errorLabel.heightAnchor.constraint(equalToConstant: 29)
        ])
    }
}

// MARK: - UITextFieldDelegate
extension NewListCellItem: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= maxNameleLenght
    }
}
