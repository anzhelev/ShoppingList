import UIKit

class NewListViewController: UIViewController {
    
    // MARK: - Private Properties
    private let viewModel: NewListViewModelProtocol
    
    private lazy var listItemsTable = {
        let table = UITableView()
        table.register(NewListCellTitle.self, forCellReuseIdentifier: NewListCellTitle.reuseIdentifier)
        table.register(NewListCellItem.self, forCellReuseIdentifier: NewListCellItem.reuseIdentifier)
        table.register(NewListCellButton.self, forCellReuseIdentifier: NewListCellButton.reuseIdentifier)
        table.delegate = self
        table.dataSource = self
        table.showsVerticalScrollIndicator = false
        table.separatorStyle = .none
        table.separatorColor = .tableSeparator
        table.backgroundColor = .clear
        table.allowsSelection = false
        return table
    }()
    
    private lazy var completeButton = {
        let button = UIButton()
        button.setTitle(.buttonSaveList, for: .normal)
        button.setTitleColor(.buttonTextPrimary, for: .normal)
        button.titleLabel?.font = .listScreenTitle
        button.backgroundColor = .buttonBgrTertiary
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(completeButtonPressed), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initializers
    init(viewModel: NewListViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        bindViewModel()
        setUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        viewModel.viewWillAppear()
        updateCompleteButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        viewModel.viewWillDisappear()
    }
    
    // MARK: - Actions
    @objc private func completeButtonPressed() {
        viewModel.completeButtonPressed()
    }
    
    // MARK: - Private Methods
    private func bindViewModel() {
        viewModel.newListBinding.bind {[weak self] tasks in
            guard let tasks else { return }
            for task in tasks {
                switch task {
                case .interactionEnabled(let state):
                    self?.listItemsTable.isUserInteractionEnabled = state
                    
                case .updateCompleteButtonState:
                    self?.updateCompleteButton()
                    
                case .showPopUp(let row, let quantity, let unit):
                    self?.showPopUpView(for: row, quantity: quantity, unit: unit)
                    
                case .updateItems(let indexes, let option):
                    self?.listItemsTable.isUserInteractionEnabled = !option
                    self?.reloadItems(indexes: indexes, animated: option)
                    
                case .insertItem(let indexPath):
                    self?.listItemsTable.isUserInteractionEnabled = false
                    self?.insertItem(index: indexPath)
                    
                case .removeItem(let indexPath):
                    self?.listItemsTable.isUserInteractionEnabled = false
                    self?.removeItem(index: indexPath)
                    
                case .reloadTable:
                    self?.listItemsTable.reloadData()
                }
            }
        }
    }
    
    private func reloadItems(indexes: [IndexPath], animated: Bool) {
        listItemsTable.performBatchUpdates {
            listItemsTable.reloadRows(at: indexes, with: animated ? .automatic : .none)
        } completion: {_ in
            self.updateCompleteButton()
            self.listItemsTable.isUserInteractionEnabled = true
            self.viewModel.tableFinishedUpdating()
        }
    }
    
    private func insertItem(index: IndexPath) {
        listItemsTable.performBatchUpdates {
            listItemsTable.insertRows(at: [index], with: .bottom)
        } completion: {_ in
            self.updateCompleteButton()
            self.listItemsTable.isUserInteractionEnabled = true
            self.viewModel.tableFinishedUpdating()
        }
    }
    
    private func removeItem(index: IndexPath) {
        listItemsTable.performBatchUpdates {
            listItemsTable.deleteRows(at: [index], with: .top)
        } completion: {_ in
            self.updateCompleteButton()
            self.listItemsTable.isUserInteractionEnabled = true
            self.viewModel.tableFinishedUpdating()
        }
    }
    
    private func setUI() {
        self.view.backgroundColor = .screenBgrPrimary
        navBarConfig()
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        [completeButton, listItemsTable].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            listItemsTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            listItemsTable.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            listItemsTable.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            listItemsTable.bottomAnchor.constraint(equalTo: completeButton.topAnchor, constant: -24),
            
            completeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            completeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            completeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            completeButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    
    private func navBarConfig() {
        let titleView = UILabel()
        titleView.text = viewModel.getListTitle()
        titleView.textColor = .textColorPrimary
        titleView.font = .listScreenTitle
        navigationItem.titleView = titleView
    }
    
    private func updateCompleteButton() {
        let enableState = viewModel.getCompleteButtonState()
        completeButton.isEnabled = enableState
        completeButton.backgroundColor = enableState ? .buttonBgrTertiary : .buttonBgrDisabled
        
        enableState
        ? completeButton.setTitleColor(.buttonTextPrimary, for: .normal)
        : completeButton.setTitleColor(.buttonTextSecondary, for: .normal)
        
        self.viewModel.tableFinishedUpdating()
    }
    
    private func showPopUpView(for item: Int, quantity: Float, unit: Units) {
        let popUpView = PopUpAssembler().build(item: item, delegate: self.viewModel as? PopUpVCDelegate, quantity: quantity, unit: unit)
        if let sheet = popUpView.sheetPresentationController {
            let detent: UISheetPresentationController.Detent = .custom(identifier: .init(rawValue: "custom")) { _ in 224 }
            sheet.detents = [detent]
            sheet.preferredCornerRadius = 24
            sheet.prefersGrabberVisible = true
        }
        
        present(popUpView, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension NewListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.getTableRowCount()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        viewModel.getRowHeight(for: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellParams = viewModel.getCellParams(for: indexPath.row)
        
        switch cellParams.0 {
            
        case .title:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: NewListCellTitle.reuseIdentifier,
                for: indexPath
            ) as? NewListCellTitle else {
                return UITableViewCell()
            }
            cell.delegate = viewModel as? NewListCellDelegate
            cell.configure(with: cellParams.1)
            return cell
            
        case .item:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: NewListCellItem.reuseIdentifier,
                for: indexPath
            ) as? NewListCellItem else {
                return UITableViewCell()
            }
            cell.delegate = viewModel as? NewListCellDelegate
            cell.configure(with: cellParams.1)
            return cell
            
        case .button:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: NewListCellButton.reuseIdentifier,
                for: indexPath
            ) as? NewListCellButton else {
                return UITableViewCell()
            }
            cell.delegate = viewModel as? NewListCellDelegate
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension NewListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard indexPath.row != 0,
              indexPath.row != viewModel.getTableRowCount() - 1 else {
            return nil
        }
        
        let primaryAction = UIContextualAction(style: .destructive,
                                               title: .buttonDelete) { [weak self] (action, view, completionHandler) in
            self?.viewModel.deleteItemButtonPressed(in: indexPath.row)
            completionHandler(true)
        }
        primaryAction.backgroundColor = .buttonBgrSecondary
        
        return UISwipeActionsConfiguration(actions: [primaryAction])
    }
}
