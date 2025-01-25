import UIKit

final class ShoppingListsTableCell: UITableViewCell {
    
    // MARK: - Public Properties
    static let reuseIdentifier = "shoppingListsTableCell"
    
    // MARK: - Private Properties
    private let pinImageView = {
        UIImageView(image: UIImage(named: "pin")?.withTintColor(.textColorPrimary))
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textColorPrimary
        label.font = .itemName
        label.textAlignment = .left
        return label
    }()
    
    private let pinnedTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textColorPrimary
        label.font = .itemName
        label.textAlignment = .left
        return label
    }()
    
    private let rightSideImageView = UIImageView()
    
    private lazy var rightSideView = {
        let view = UIView()
        rightSideImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rightSideImageView)
        rightSideImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        rightSideImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        return view
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
    func configure(with params: MainScreenTableCellParams) {
        self.selectionStyle = .none
        
        pinImageView.isHidden = !params.pinned
        pinnedTitleLabel.isHidden = !params.pinned
        titleLabel.isHidden = params.pinned
        
        titleLabel.text = params.title
        pinnedTitleLabel.text = params.title
        
        titleLabel.textColor = params.completeMode
        ? .textColorSecondary
        : .textColorPrimary
        
        rightSideImageView.image = params.completeMode
        ? UIImage(named: "listCheckmark")?.withTintColor(.buttonBgrPrimary)
        : UIImage(named: "arrowRight")?.withTintColor(.listItemRightArrow)
        
        separatorInset = params.separator
        ? UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        : UIEdgeInsets(top: 0, left: self.bounds.width + 40, bottom: 0, right: 0)
    }
    
    // MARK: - Private Methods
    private func setUIElements() {
        self.backgroundColor = .screenBgrPrimary
        [pinImageView, titleLabel, pinnedTitleLabel, rightSideView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
            $0.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        }
        
        NSLayoutConstraint.activate([
            pinImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pinImageView.widthAnchor.constraint(equalToConstant: 16),
            pinnedTitleLabel.leadingAnchor.constraint(equalTo: pinImageView.trailingAnchor, constant: 8),
            pinnedTitleLabel.trailingAnchor.constraint(equalTo: rightSideView.leadingAnchor, constant: -16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: rightSideView.leadingAnchor, constant: -16),
            rightSideView.widthAnchor.constraint(equalToConstant: 17),
            rightSideView.topAnchor.constraint(equalTo: contentView.topAnchor),
            rightSideView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }
}
