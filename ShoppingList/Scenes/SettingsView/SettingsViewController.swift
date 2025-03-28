import UIKit

final class SettingsViewController: UIViewController {
    
    // MARK: - Private Properties
    private let viewModel: SettingsViewModelProtocol
    
    private let themeLabel = UILabel()
    private lazy var themeSegmentedControl: UISegmentedControl = {
        var view = UISegmentedControl(items: viewModel.themes)
        view.selectedSegmentIndex = viewModel.getTheme()
        view.addTarget(self, action: #selector(themeChanged), for: .valueChanged)
        return view
    }()
    
    private let languageLabel = UILabel()
    private lazy var languageSelectionTable: UITableView = {
        let table = UITableView()
        table.register(SettingsLanguageCell.self, forCellReuseIdentifier: SettingsLanguageCell.reuseIdentifier)
        table.delegate = self
        table.dataSource = self
        table.isScrollEnabled = false
        table.showsVerticalScrollIndicator = false
        table.separatorStyle = .singleLine
        table.separatorColor = .tableSeparator
        table.backgroundColor = .clear
        return table
    }()
    
    private let fontSizeLabel = UILabel()
    //    private let fontSizeSegmentedControl = UISegmentedControl(items: ["Small", "Large"])
    
    // MARK: - Initializers
    init(viewModel: SettingsViewModelProtocol) {
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
        setupUI()
    }
    
    // MARK: - Actions
    @objc private func themeChanged() {
        viewModel.setTheme(themeIndex: themeSegmentedControl.selectedSegmentIndex)
    }
    
    @objc private func fontSizeChanged() {
        
    }
    
    // MARK: - Private Methods
    private func bindViewModel() {
        viewModel.settingsBinding.bind {[weak self] value in
            guard let value else {
                return
            }
            switch value {
            case .showAlert(let title, let message, let buttonName):
                self?.showAlert(with: title, message: message, buttonTitle: buttonName)
                self?.reloadLanguageSelectionTable()
            }
        }
    }
    
    private func setVStackView(title: String, option: UIView) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, option])
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        stackView.distribution = .fillProportionally
        
        return stackView
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let stackView = UIStackView(arrangedSubviews: [
            setVStackView(title: viewModel.languageStackTitle, option: languageSelectionTable),
            setVStackView(title: viewModel.themeStackTitle, option: themeSegmentedControl),
            //            setVStackView(title: "Размер шрифта", option: fontSizeSegmentedControl)
        ]
        )
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            languageSelectionTable.heightAnchor.constraint(equalToConstant: 130),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.heightAnchor.constraint(equalToConstant: 240)
        ])
        
        themeSegmentedControl.addTarget(self, action: #selector(themeChanged), for: .valueChanged)
        //TODO:        fontSizeSegmentedControl.addTarget(self, action: #selector(fontSizeChanged), for: .valueChanged)
    }
    
    private func reloadLanguageSelectionTable() {
        languageSelectionTable.reloadData()
    }
    
    private func showAlert(with title: String, message: String, buttonTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.getTableRowCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsLanguageCell.reuseIdentifier, for: indexPath) as! SettingsLanguageCell
        
        cell.configure(with: viewModel.getCellParams(for: indexPath.row))
        return cell
    }
}


// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.languageSelected(indexPath.row)
    }
}
