import UIKit

final class NewListCellTitle: UITableViewCell {
    
    // MARK: - Public Properties
    static let reuseIdentifier = "newListCellTitle"
    weak var delegate: NewListCellDelegate?
    
    // MARK: - Private Properties
    private let maxTitleLenght = 20
    
    private lazy var titleTextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.clearButtonMode = .always
        textField.tintColor = .textColorPrimary
        textField.textColor = .textColorPrimary
        textField.font = .itemName
        textField.placeholder = .newListTitlePlaceholder
        textField.clearButtonMode = .whileEditing
        return textField
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
        titleTextField.text = params.title
        titleTextField.textColor = params.error == nil ? .textColorPrimary : .buttonBgrSecondary
        separatorView.backgroundColor = params.error == nil ? .tableSeparator : .buttonBgrSecondary
        errorLabel.text = params.error
        errorLabel.isHidden = params.error == nil
    }
    
    // MARK: - Private Methods
    private func setUIElements() {
        self.backgroundColor = .screenBgrPrimary
        [titleTextField, separatorView, errorLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
            
            $0.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            $0.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        }
        
        titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        titleTextField.heightAnchor.constraint(equalToConstant: 46).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: titleTextField.bottomAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        errorLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor).isActive = true
        errorLabel.heightAnchor.constraint(equalToConstant: 29).isActive = true
    }
}

// MARK: - UITextFieldDelegate
extension NewListCellTitle: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textFieldDidBeginEditing()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        self.delegate?.updateNewListTitle(with: self.titleTextField.text)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= maxTitleLenght
    }
}
