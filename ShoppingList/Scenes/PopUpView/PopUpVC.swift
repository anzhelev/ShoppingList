import UIKit

final class PopUpVC: UIViewController {
    
    // MARK: - Private Properties
    private let viewModel: PopUpViewModelProtocol?
    
    private let maxIntegerPlaces = 3
    private let maxDecimalPlaces = 1
    private let decimalSeparator = "."
    
    private lazy var unitSelector = {
        let selector = UISegmentedControl(
            items: [NSLocalizedString(Units.kg.rawValue, comment: ""),
                    NSLocalizedString(Units.liter.rawValue, comment: ""),
                    NSLocalizedString(Units.pack.rawValue, comment: ""),
                    NSLocalizedString(Units.piece.rawValue, comment: "")
                   ]
        )
        selector.setTitleTextAttributes(
            [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.font: UIFont.segmentControlNormal
            ],
            for: .normal
        )
        selector.setTitleTextAttributes(
            [
                NSAttributedString.Key.foregroundColor: UIColor.black,
                NSAttributedString.Key.font: UIFont.segmentControlSelected
            ],
            for: .selected
        )
        selector.backgroundColor = .unitSelectionBlockBgr
        selector.selectedSegmentTintColor = .white
        selector.layer.cornerRadius = 10
        selector.layer.masksToBounds = true
        selector.addTarget(self, action: #selector(unitSelected), for: .valueChanged)
        return selector
    }()
    
    private lazy var minusButton = {
        UIButton.systemButton(
            with: UIImage(named: "buttonMinus")?.withTintColor(.textColorPrimary, renderingMode: .alwaysOriginal) ?? UIImage(),
            target: self,
            action: #selector(self.minusButtonPressed)
        )
        
    }()
    
    private lazy var plusButton = {
        UIButton.systemButton(
            with: UIImage(named: "buttonPlus")?.withTintColor(.textColorPrimary, renderingMode: .alwaysOriginal) ?? UIImage(),
            target: self,
            action: #selector(self.plusButtonPressed)
        )
    }()
    
    private lazy var quantityTextField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.textColor = .textColorPrimary
        textField.font = .mainScreenStub
        textField.textAlignment = .center
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 18
        textField.layer.masksToBounds = true
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.listItemRightArrow.cgColor
        textField.keyboardType = .numberPad
        textField.inputAccessoryView = createKeyboardToolbar()
        return textField
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)
        button.setTitle(.buttonDone, for: .normal)
        button.titleLabel?.font = .listScreenTitle
        button.setTitleColor(.buttonTextPrimary, for: .normal)
        button.backgroundColor = .buttonBgrTertiary
        button.layer.cornerRadius = 10
        return button
    }()
    
    // MARK: - Initializers
    init(viewModel: PopUpViewModelProtocol) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        setUIElements()
    }
    
    // MARK: - Actions
    @objc private func unitSelected() {
        viewModel?.unitSelected(unit: unitSelector.selectedSegmentIndex)
    }
    
    @objc private func doneButtonPressed() {
        viewModel?.doneButtonPressed()
    }
    
    @objc private func minusButtonPressed() {
        viewModel?.minusButtonPressed(for: quantityTextField.text)
    }
    
    @objc private func plusButtonPressed() {
        viewModel?.plusButtonPressed(for: quantityTextField.text)
    }
    
    @objc private func insertDecimalSeparator() {
        guard let currentText = quantityTextField.text else { return }
        
        if !currentText.contains(decimalSeparator) {
            quantityTextField.insertText(decimalSeparator)
        }
    }
    
    @objc private func clearText() {
        quantityTextField.text = ""
    }
    
    @objc private func endEditing() {
        quantityTextField.resignFirstResponder()
        viewModel?.quantityUpdated(with: quantityTextField.text)
    }
    
    // MARK: - Private Methods
    private func bindViewModel() {
        viewModel?.popUpBinding.bind { [weak self] value in
            switch value {
                
            case .closePopUp:
                self?.dismiss(animated: true)
                
            case .popUpQuantity(let quantity):
                self?.quantityTextField.text = quantity
                
            case .popUpUnit(let unit):
                self?.setUnitSelectorValue(unit: unit)
                
            default:
                return
            }
        }
    }
    
    private func createKeyboardToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let clearButton = UIBarButtonItem(
            title: "Очистить",
            style: .plain,
            target: self,
            action: #selector(clearText))
       
        let separatorButton = UIBarButtonItem(
            title: decimalSeparator,
            style: .plain,
            target: self,
            action: #selector(insertDecimalSeparator)
        )
        
        separatorButton.tintColor = .textColorPrimary
        
        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        
        let doneButton = UIBarButtonItem(
            title: "Готово",
            style: .done,
            target: self,
            action: #selector(endEditing)
        )
        
        toolbar.items = [clearButton, flexibleSpace, separatorButton, flexibleSpace, doneButton]
        
        return toolbar
    }

    private func setUIElements() {
        view.backgroundColor = .screenBgrPrimary
        
        quantityTextField.text = viewModel?.getQuantity() ?? "1"
        setUnitSelectorValue(unit: viewModel?.getUnitIndex() ?? 3)
        
        [unitSelector, minusButton, plusButton, quantityTextField, doneButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        [unitSelector, minusButton, doneButton].forEach {
            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        }
        
        [unitSelector, quantityTextField, doneButton].forEach {
            $0.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        }
        
        [minusButton, plusButton].forEach {
            $0.widthAnchor.constraint(equalToConstant: 50).isActive = true
            $0.heightAnchor.constraint(equalTo: $0.widthAnchor).isActive = true
        }
        
        NSLayoutConstraint.activate([
            unitSelector.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            unitSelector.heightAnchor.constraint(equalToConstant: 32),
            minusButton.topAnchor.constraint(equalTo: unitSelector.bottomAnchor, constant: 15),
            quantityTextField.centerYAnchor.constraint(equalTo: minusButton.centerYAnchor),
            plusButton.centerYAnchor.constraint(equalTo: minusButton.centerYAnchor),
            plusButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.topAnchor.constraint(equalTo: plusButton.bottomAnchor, constant: 32),
            doneButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func setUnitSelectorValue(unit: Int) {
        unitSelector.selectedSegmentIndex = unit
    }
}

// MARK: - UITextFieldDelegate
extension PopUpVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let currentText = textField.text else { return true }
        
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        if let separatorRange = newText.range(of: decimalSeparator) {
            let decimalPart = newText[separatorRange.upperBound...]
            let integerPart = newText[..<separatorRange.lowerBound]
            return decimalPart.count <= maxDecimalPlaces && integerPart.count <= maxIntegerPlaces
        } else {
            return newText.count <= maxIntegerPlaces
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        endEditing()
    }
}
