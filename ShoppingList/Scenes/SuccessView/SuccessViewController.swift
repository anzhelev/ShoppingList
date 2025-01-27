import UIKit

class SuccessViewController: UIViewController {
    
    // MARK: - Private Properties
    private let viewModel: SuccessViewModel
    
    private lazy var titleLabel = {
        let label = UILabel()
        label.text = self.viewModel.getListName()
        label.font = .listScreenTitle
        label.textColor = .textColorPrimary
        label.textAlignment = .center
        return label
    }()
    
    private let logoImageView = UIImageView(image: UIImage(named: "successScreenImage"))
    
    private let congratulationsLabel = {
        let label = UILabel()
        label.text = .successViewCongratulations
        label.font = .mainScreenStub
        label.textColor = .textColorPrimary
        label.textAlignment = .center
        return label
    }()
    
    private let additionalLabel = {
        let label = UILabel()
        label.text = .successViewAdditional
        label.font = .itemName
        label.textColor = .textColorPrimary
        label.textAlignment = .center
        label.numberOfLines = 3
        return label
    }()
    
    private lazy var bottomButton = {
        let button = UIButton()
        button.setTitle(.buttonSwitchToMainScreen, for: .normal)
        button.setTitleColor(.buttonTextPrimary, for: .normal)
        button.backgroundColor = .buttonBgrTertiary
        button.titleLabel?.font = .listScreenTitle
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        return button
    }()
    
    //MARK: - Initializers
    init(viewModel: SuccessViewModel) {
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
        setUI()
    }
    
    // MARK: - Actions
    @objc private func buttonPressed() {
        viewModel.buttonTapped()
    }
    
    // MARK: - Private Methods
    private func bindViewModel() {
        viewModel.switchToMainView.bind {[weak self] value in
            guard let value else {
                return
            }
            if value {
                self?.switchToMainView()
            }
        }
    }
    
    private func setUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .successViewBgr
        
        [titleLabel, logoImageView, congratulationsLabel, additionalLabel, bottomButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
            
            $0.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            titleLabel.heightAnchor.constraint(equalToConstant: 44),
            
            logoImageView.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: 0),
            
            congratulationsLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 87),
            additionalLabel.topAnchor.constraint(equalTo: congratulationsLabel.bottomAnchor, constant: 10),
            
            bottomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            bottomButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            bottomButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func switchToMainView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.pushViewController(MainScreenAssembler().build(completeMode: true), animated: true)
    }
}
