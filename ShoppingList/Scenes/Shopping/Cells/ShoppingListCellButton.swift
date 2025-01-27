import UIKit

protocol ShoppingListCellButtonDelegate: AnyObject {
    func addNewItemButtonPressed()
}

final class ShoppingListCellButton: UITableViewCell {
    
    // MARK: - Public Properties
    static let reuseIdentifier = "shoppingListCellButton"
    weak var delegate: ShoppingListCellButtonDelegate?
    
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
    
    // MARK: - Lifecycle
    override func layoutSubviews() {
        super.layoutSubviews()
        let margins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        contentView.frame = contentView.frame.inset(by: margins)
    }
    
    // MARK: - IBAction
    @objc func addButtonPressed() {
        self.delegate?.addNewItemButtonPressed()
    }
    
    // MARK: - Private Methods
    private func setUIElements() {
        self.backgroundColor = .screenBgrPrimary
        addButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(addButton)
        
        addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        addButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
    }
}
