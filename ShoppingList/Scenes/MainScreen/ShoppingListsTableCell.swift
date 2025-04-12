import UIKit

final class ShoppingListsTableCell: UITableViewCell {
    
    // MARK: - Public Properties
    static let reuseIdentifier = "shoppingListsTableCell"
    
    // MARK: - Private Properties
    private let pinImageView = UIImageView(image: UIImage(named: "pin")?.withTintColor(.textColorPrimary))
    private let chevronImageView = UIImageView()
    private var mainStackView = UIStackView()
    private lazy var listTitleLabel = createLabel(font: .itemName)
    private lazy var listDateLabel = createLabel(font: .hintLabel)
    
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
    func configure(with params: MainScreenTableCellParams) {
        self.selectionStyle = .none
        
        mainStackView.arrangedSubviews[0].isHidden = !params.pinned
        
        listTitleLabel.text = params.title
        
        listTitleLabel.textColor = params.completeMode
        ? .textColorSecondary
        : .textColorPrimary
        
        listDateLabel.text = params.date
        listDateLabel.textColor = .textColorTertiary
        
        chevronImageView.image = params.completeMode
        ? UIImage(named: "listCheckmark")?.withTintColor(.buttonBgrPrimary)
        : UIImage(named: "arrowRight")?.withTintColor(.listItemRightArrow)
        
        separatorInset = params.separator
        ? UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        : UIEdgeInsets(top: 0, left: self.bounds.width + 40, bottom: 0, right: 0)
    }
    
    // MARK: - Private Methods
    private func setUIElements() {
        self.backgroundColor = .screenBgrPrimary
        
        let chevronView = UIView()
        chevronView.addSubview(chevronImageView)
        let labelStackView = createLabelStackView(labels: [listTitleLabel, listDateLabel])
        mainStackView = createMainStackView(labels: [pinImageView, labelStackView, chevronView])
        
        [mainStackView, chevronImageView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        contentView.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            pinImageView.widthAnchor.constraint(equalToConstant: 16),
            chevronImageView.centerYAnchor.constraint(equalTo: chevronView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: chevronView.trailingAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 17)
        ])
    }
    
    private func createMainStackView(labels: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: labels)
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }
    
    private func createLabelStackView(labels: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: labels)
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 8
        return stackView
    }
    
    private func createLabel(font: UIFont) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textAlignment = .left
        return label
    }
}
