import UIKit

final class PopUpVC: UIViewController {
    
    // MARK: - Private Properties
    private let viewModel: PopUpViewModelProtocol?
    
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
    
    private lazy var quantityLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textColorPrimary
        label.font = .itemName
        label.textAlignment = .center
        return label
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
        viewModel?.minusButtonPressed()
    }
    
    @objc private func plusButtonPressed() {
        viewModel?.plusButtonPressed()
    }
    
    // MARK: - Private Methods
    private func bindViewModel() {
        viewModel?.popUpBinding.bind { [weak self] value in
            switch value {
                
            case .closePopUp:
                self?.dismiss(animated: true)
                
            case .popUpQuantity(let quantity):
                self?.quantityLabel.text = "\(quantity)"
                
            case .popUpUnit(let unit):
                self?.setUnitSelectorValue(unit: unit)
                
            default:
                return
            }
        }
    }
    
    private func setUIElements() {
        view.backgroundColor = .screenBgrPrimary
        
        quantityLabel.text = "\(viewModel?.getQuantity() ?? 1)"
        setUnitSelectorValue(unit: viewModel?.getUnitIndex() ?? 3)
        
        [unitSelector, minusButton, plusButton, quantityLabel, doneButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        [unitSelector, minusButton, doneButton].forEach {
            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        }
        
        [unitSelector, quantityLabel, doneButton].forEach {
            $0.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        }
        
        [minusButton, plusButton].forEach {
            $0.widthAnchor.constraint(equalToConstant: 50).isActive = true
            $0.heightAnchor.constraint(equalTo: $0.widthAnchor).isActive = true
        }
        
        NSLayoutConstraint.activate([
            unitSelector.heightAnchor.constraint(equalToConstant: 32),
            minusButton.topAnchor.constraint(equalTo: unitSelector.bottomAnchor, constant: 15),
            quantityLabel.centerYAnchor.constraint(equalTo: minusButton.centerYAnchor),
            plusButton.centerYAnchor.constraint(equalTo: minusButton.centerYAnchor),
            plusButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.topAnchor.constraint(equalTo: plusButton.bottomAnchor, constant: 32),
            doneButton.heightAnchor.constraint(equalToConstant: 48),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }
    
    private func setUnitSelectorValue(unit: Int) {
        unitSelector.selectedSegmentIndex = unit
    }
}
