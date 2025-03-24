import UIKit

class MainScreenViewController: UIViewController {
    
    // MARK: - Private Properties
    private let viewModel: MainScreenViewModelProtocol
    
    private let titleLabel = {
        let label = UILabel()
        label.textColor = .textColorPrimary
        label.font = .mainScreenTitle
        label.textAlignment = .left
        label.numberOfLines = 2
        return label
    }()
    
    private let stubLabel = {
        let label = UILabel()
        label.text = .mainScreenStub
        label.textColor = .textColorPrimary
        label.font = .mainScreenStub
        label.textAlignment = .center
        label.numberOfLines = 3
        label.isHidden = true
        return label
    }()
    
    private let arrowImageView = {
        let imageView = UIImageView(image: UIImage(named: "blueArrow"))
        imageView.isHidden = true
        return imageView
    }()
    
    private let backgroundImageView = {
        let imageView = UIImageView(image: UIImage(named: "listBgrImage"))
        imageView.alpha = 0.5
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var addNewListButton = {
        UIButton.systemButton(
            with: UIImage(named: "buttonPlus")?.withTintColor(.buttonBgrPrimary, renderingMode: .alwaysOriginal) ?? UIImage(),
            target: self,
            action: #selector(addNewListButtonPressed)
        )
    }()
    
    private lazy var shoppingListsTable = {
        let table = UITableView()
        table.register(ShoppingListsTableCell.self, forCellReuseIdentifier: ShoppingListsTableCell.reuseIdentifier)
        table.delegate = self
        table.dataSource = self
        table.showsVerticalScrollIndicator = false
        table.separatorStyle = .singleLine
        table.separatorColor = .tableSeparator
        table.backgroundColor = .clear
        return table
    }()
    
    // MARK: - Initializers
    init(viewModel: MainScreenViewModelProtocol) {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(true, animated: true)
        viewModel.viewWillAppear()
        updateStub()
    }
    
    // MARK: - Actions
    @objc private func addNewListButtonPressed() {
        viewModel.addNewListButtonPressed()
    }
    
    // MARK: - Private Methods
    private func bindViewModel() {
        viewModel.mainScreenBinding.bind {[weak self] value in
            switch value {
                
            case .reloadTable:
                self?.reloadTable()
                
            case .updateItem(let indexPath):
                self?.reloadItem(index: indexPath)
                
            case .removeItem(let indexPath):
                self?.removeItem(index: indexPath)
                self?.updateStub()
                
            default:
                return
            }
        }
    }
    
    private func reloadTable() {
        shoppingListsTable.reloadData()
    }
    
    private func reloadItem(index: IndexPath) {
        shoppingListsTable.beginUpdates()
        shoppingListsTable.reloadRows(at: [index], with: .right)
        shoppingListsTable.endUpdates()
    }
    
    private func removeItem(index: IndexPath) {
        shoppingListsTable.beginUpdates()
        shoppingListsTable.deleteRows(at: [index], with: .top)
        if index.row > 0 {
            shoppingListsTable.reloadRows(at: [.init(row: index.row - 1, section: 0)], with: .none)
        }
        shoppingListsTable.endUpdates()
    }
    
    private func updateStub() {
        let stubStatus = viewModel.getStubState()
        stubLabel.isHidden = !stubStatus
        arrowImageView.isHidden = !stubStatus
        backgroundImageView.isHidden = stubStatus
        shoppingListsTable.isHidden = stubStatus
    }
    
    private func setUI() {
        self.view.backgroundColor = .screenBgrPrimary
        titleLabel.text = viewModel.getScreenTitle()
        
        [titleLabel, stubLabel, arrowImageView, backgroundImageView, addNewListButton, shoppingListsTable].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            stubLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stubLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stubLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            addNewListButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            addNewListButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addNewListButton.heightAnchor.constraint(equalToConstant: 50),
            addNewListButton.widthAnchor.constraint(equalTo: addNewListButton.heightAnchor),
            
            arrowImageView.topAnchor.constraint(equalTo: stubLabel.bottomAnchor, constant: 13),
            arrowImageView.bottomAnchor.constraint(equalTo: addNewListButton.topAnchor, constant: 10),
            arrowImageView.leadingAnchor.constraint(equalTo: addNewListButton.trailingAnchor, constant: -15),
            arrowImageView.widthAnchor.constraint(equalTo: arrowImageView.heightAnchor, multiplier: 127/267.5),
            
            backgroundImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 62),
            backgroundImageView.widthAnchor.constraint(equalTo: backgroundImageView.heightAnchor, multiplier: 250/113),
            backgroundImageView.bottomAnchor.constraint(equalTo: addNewListButton.topAnchor, constant: -16),
            
            shoppingListsTable.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            shoppingListsTable.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            shoppingListsTable.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            shoppingListsTable.bottomAnchor.constraint(equalTo: backgroundImageView.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource
extension MainScreenViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.getTableRowCount()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        64
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ShoppingListsTableCell.reuseIdentifier,
            for: indexPath
        ) as? ShoppingListsTableCell else {
            debugPrint("@@@: Ошибка подготовки ячейки для таблицы.")
            return UITableViewCell()
        }
        cell.configure(with: viewModel.getCellParams(for: indexPath.row))
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MainScreenViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.listSelected(row: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let primaryAction = UIContextualAction(style: .normal,
                                               title: self.viewModel.getPrimaryButtonTitle(for: indexPath.row)) { [weak self] (action, view, completionHandler) in
            self?.viewModel.primaryActionButtonPressed(in: indexPath.row)
            completionHandler(true)
        }
        primaryAction.backgroundColor = .buttonBgrPrimary
        
        let secondaryAction = UIContextualAction(style: .destructive,
                                                 title: .buttonDelete) { [weak self] (action, view, completionHandler) in
            self?.viewModel.deleteListButtonPressed(in: indexPath.row)
            completionHandler(true)
        }
        secondaryAction.backgroundColor = .buttonBgrSecondary
        
        return UISwipeActionsConfiguration(actions: [secondaryAction, primaryAction])
    }
    
    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let primaryAction = UIContextualAction(style: .normal,
                                               title: .buttonEdit) { [weak self] (action, view, completionHandler) in
            self?.viewModel.editButtonPressed(in: indexPath.row)
            completionHandler(true)
        }
        primaryAction.backgroundColor = .buttonBgrPrimary
        
        return UISwipeActionsConfiguration(actions: [primaryAction])
    }
}
