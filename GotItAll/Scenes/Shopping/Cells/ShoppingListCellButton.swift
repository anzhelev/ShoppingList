import UIKit

final class ShoppingListCellButton: UITableViewCell {

    // MARK: - Public Properties
    static let reuseIdentifier = "shoppingListCellButton"
    weak var delegate: ShoppingListCellDelegate?

    // MARK: - Private Properties
    private lazy var addButton = {
        let button = UIButton()
        button.setTitleColor(.buttonBgrPrimary, for: .normal)
        button.setTitle(.buttonAddProduct, for: .normal)
        button.titleLabel?.font = .itemName
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(self.addButtonPressed), for: .touchUpInside)
        return button
    }()

    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setUIElements()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Methods
    private func setUIElements() {
        self.backgroundColor = .screenBgrPrimary
        addButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(addButton)

        addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        addButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
    }

    // MARK: - Actions
    @objc func addButtonPressed() {
        self.delegate?.addNewItemButtonPressed()
    }
}
