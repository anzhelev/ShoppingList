import UIKit

final class NewListCellButton: UITableViewCell {    
    // MARK: - Public Properties
    static let reuseIdentifier = "newListCellButton"
    weak var delegate: NewListCellDelegate?
    
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
    
    private let hintLabel = {
        let label = UILabel()
        label.textColor = .textColorTertiary
        label.font = .hintLabel
        label.textAlignment = .left
        label.text = .newListAddProductHint
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
    
    // MARK: - IBAction
    @objc func addButtonPressed() {
        self.delegate?.addNewItemButtonPressed()
    }
    
    // MARK: - Private Methods
    private func setUIElements() {
        self.backgroundColor = .screenBgrPrimary
        [addButton, hintLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
            $0.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        }
        
        addButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        hintLabel.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 0).isActive = true
        hintLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true
    }
}
