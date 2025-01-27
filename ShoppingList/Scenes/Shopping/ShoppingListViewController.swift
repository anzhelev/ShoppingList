import UIKit

class ShoppingListViewController: UIViewController {
    
    // MARK: - Private Properties
    private let viewModel: ShoppingListViewModelProtocol
    
    private lazy var checkAllSwitch = {
        let switchView = UISwitch()
        switchView.addTarget(self, action: #selector(checkAllSwitchValueChanged), for: .valueChanged)
        return switchView
    }()
    
    private lazy var checkAllSwithBlock = {
        let block = UIView()
        let label = UILabel()
        label.text = .shoppingListVCcheckAll
        label.font = .itemName
        label.textAlignment = .left
        label.textColor = .textColorPrimary
        [label, checkAllSwitch].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            block.addSubview($0)
            $0.centerYAnchor.constraint(equalTo: block.centerYAnchor).isActive = true
        }
        label.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 16).isActive = true
        checkAllSwitch.trailingAnchor.constraint(equalTo: block.trailingAnchor, constant: -16).isActive = true
        
        return block
    }()
    
    private lazy var listItemsTable = {
        let table = UITableView()
        table.register(ShoppingListCellItem.self, forCellReuseIdentifier: ShoppingListCellItem.reuseIdentifier)
        table.register(ShoppingListCellButton.self, forCellReuseIdentifier: ShoppingListCellButton.reuseIdentifier)
        table.delegate = self
        table.dataSource = self
        table.dragInteractionEnabled = true
        table.dropDelegate = self
        table.showsVerticalScrollIndicator = false
        table.separatorStyle = .none
        table.separatorColor = .tableSeparator
        table.backgroundColor = .clear
        table.allowsSelection = false
        return table
    }()
    
    private lazy var bottomButton = {
        let button = UIButton()
        button.setTitle(viewModel.getBottomButtonName(), for: .normal)
        button.setTitleColor(.buttonTextPrimary, for: .normal)
        button.titleLabel?.font = .listScreenTitle
        button.backgroundColor = .buttonBgrPrimary
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(bottomButtonPressed), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initializers
    init(viewModel: ShoppingListViewModelProtocol) {
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
    }
    
    
    // MARK: - Actions
    @objc private func sortButtonPressed() {
        viewModel.sortButtonPressed()
    }
    
    @objc private func checkAllSwitchValueChanged() {
        viewModel.checkAllSwitchIs(on: checkAllSwitch.isOn)
    }
    
    @objc private func bottomButtonPressed() {
        viewModel.bottomButtonPressed()
    }
    
    // MARK: - Private Methods
    private func bindViewModel() {
        viewModel.userInteractionEnabled.bind {[weak self] enabled in
            guard let enabled else {
                return
            }
            self?.listItemsTable.isUserInteractionEnabled = enabled
        }
        
        viewModel.switchToSuccessView.bind {[weak self] listName in
            guard let listName else {
                return
            }
            self?.switchToSuccessView(for: listName)
        }
        
        viewModel.switchToMainView.bind {[weak self] value in
            guard let value else {
                return
            }
            if value {
                self?.switchToMainView()
            }
        }
        
        viewModel.needToUpdateBottomButtonState.bind {[weak self] state in
            guard let state else {
                return
            }
            self?.updateBottomButton(isEnabled: state)
        }
        
        viewModel.needToShowPopUp.bind {[weak self] value in
            guard let value else {
                return
            }
            self?.showPopUpView(for: value.0, quantity: value.1, unit: value.2)
//            self?.showPopUpView(for: row)
        }
        
        viewModel.needToUpdateItem.bind {[weak self] value in
            guard let value else {
                return
            }
            self?.reloadItem(index: value.0, animated: value.1)
        }
        
        viewModel.needToInsertItem.bind {[weak self] indexPath in
            guard let indexPath else {
                return
            }
            self?.insertItem(index: indexPath)
        }
        
        viewModel.needToRemoveItem.bind {[weak self] indexPath in
            guard let indexPath else {
                return
            }
            self?.removeItem(index: indexPath)
        }
        
        viewModel.needToMoveItem.bind {[weak self] value in
            guard let value else {
                return
            }
            self?.moveItem(from: value.0, to: value.1)
        }
    }
    
    private func switchToSuccessView(for list: String) {
        navigationController?.pushViewController(SuccessAssembler().build(for: list), animated: true)
    }
    
    private func switchToMainView() {
        navigationController?.pushViewController(MainScreenAssembler().build(completeMode: false), animated: true)
    }
    
    private func reloadItem(index: [IndexPath], animated: Bool) {
        listItemsTable.performBatchUpdates {
            listItemsTable.reloadRows(at: index, with: animated ? .automatic : .none)
        } completion: {_ in
            self.viewModel.tableFinishedUpdating()
        }
    }
    
    private func insertItem(index: IndexPath) {
        listItemsTable.performBatchUpdates {
            listItemsTable.insertRows(at: [index], with: .bottom)
        } completion: {_ in
            self.listItemsTable.reloadData()
            self.viewModel.tableFinishedUpdating()
        }
    }
    
    private func moveItem(from oldRow: IndexPath, to newRow: IndexPath) {
        listItemsTable.performBatchUpdates {
            listItemsTable.moveRow(at: oldRow, to: newRow)
        } completion: {_ in
            self.listItemsTable.reloadData()
            self.viewModel.tableFinishedUpdating()
        }
    }
    
    private func removeItem(index: IndexPath) {
        listItemsTable.performBatchUpdates {
            listItemsTable.deleteRows(at: [index], with: .top)
        } completion: {_ in
            self.listItemsTable.reloadData()
            self.viewModel.tableFinishedUpdating()
        }
    }
    
    private func setUI() {
        self.view.backgroundColor = .screenBgrPrimary
        navBarConfig()
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        [checkAllSwithBlock, bottomButton, listItemsTable].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        if viewModel.listIsCompleted() {
            checkAllSwithBlock.isHidden = true
            checkAllSwithBlock.heightAnchor.constraint(equalToConstant: 0).isActive = true
        } else {
            checkAllSwithBlock.isHidden = false
            checkAllSwithBlock.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        
        NSLayoutConstraint.activate([
            checkAllSwithBlock.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            checkAllSwithBlock.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            checkAllSwithBlock.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            listItemsTable.topAnchor.constraint(equalTo: checkAllSwithBlock.bottomAnchor, constant: 20),
            listItemsTable.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            listItemsTable.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            listItemsTable.bottomAnchor.constraint(equalTo: bottomButton.topAnchor, constant: -24),
            
            bottomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            bottomButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            bottomButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            bottomButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    
    private func navBarConfig() {
        let titleView = UILabel()
        titleView.text = viewModel.getListTitle()
        titleView.textColor = .textColorPrimary
        titleView.font = .listScreenTitle
        navigationItem.titleView = titleView
        
        if !viewModel.listIsCompleted() {
            let sortButton = UIButton()
            sortButton.setImage(
                UIImage(named: "buttonSort")?.withTintColor(.sortButton,
                                                            renderingMode: .alwaysOriginal), for: .normal)
            sortButton.addTarget(self, action: #selector(sortButtonPressed), for: .touchUpInside)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sortButton)
        }
    }
    
    private func updateBottomButton(isEnabled: Bool) {
        bottomButton.isEnabled = isEnabled
        bottomButton.backgroundColor = isEnabled ? .buttonBgrTertiary : .buttonBgrDisabled
        
        isEnabled
        ? bottomButton.setTitleColor(.buttonTextPrimary, for: .normal)
        : bottomButton.setTitleColor(.buttonTextSecondary, for: .normal)
    }
    
    private func showPopUpView(for item: Int, quantity: Int, unit: Units) {
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
extension ShoppingListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.getTableRowCount()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        viewModel.getRowHeight(for: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellParams = viewModel.getCellParams(for: indexPath.row)
        
        switch cellParams.0 {
            
        case .item:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ShoppingListCellItem.reuseIdentifier,
                for: indexPath
            ) as? ShoppingListCellItem else {
                return UITableViewCell()
            }
            cell.delegate = viewModel as? ShoppingListCellItemDelegate
            cell.configure(for: indexPath.row, with: cellParams.1)
            return cell
            
        case .button:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ShoppingListCellButton.reuseIdentifier,
                for: indexPath
            ) as? ShoppingListCellButton else {
                return UITableViewCell()
            }
            cell.delegate = viewModel as? ShoppingListCellButtonDelegate
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension ShoppingListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard indexPath.row != viewModel.getTableRowCount() - 1 else {
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
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        self.viewModel.rowMoved(from: sourceIndexPath.row, to: destinationIndexPath.row)
        self.listItemsTable.reloadData()
    }
}

// MARK: - UITableViewDropDelegate
extension ShoppingListViewController: UITableViewDropDelegate {
    
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        true
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        
        session.items.count == 1 && tableView.hasActiveDrag
        ? UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        : UITableViewDropProposal(operation: .cancel)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
    }
}
