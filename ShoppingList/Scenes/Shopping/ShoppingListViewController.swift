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
        button.backgroundColor = .buttonBgrTertiary
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(bottomButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var datePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.minimumDate = Date()
        datePicker.maximumDate = Calendar.current.date(byAdding: .day, value: 365, to: Date())
        datePicker.roundsToMinuteInterval = true
        datePicker.minuteInterval = 5
        datePicker.preferredDatePickerStyle = .wheels
//        datePicker.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        return datePicker
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
        viewModel.viewDidLoad()
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
        viewModel.doneButtonPressed()
    }
    
    // MARK: - Private Methods
    private func bindViewModel() {
        viewModel.shoppingListBinding.bind {[weak self] value in
            
            switch value {
                
            case .showPopUp(let id, let quantity, let unit):
                self?.showPopUpView(for: id, quantity: quantity, unit: unit)
                
            case .addReminder:
                self?.addReminder()
                
            case .updateItem(let indexPath, let option):
                self?.listItemsTable.isUserInteractionEnabled = !option
                self?.reloadItem(index: indexPath, animated: option)
                
            case .insertItem(let indexPath):
                self?.listItemsTable.isUserInteractionEnabled = false
                self?.insertItem(index: indexPath)
                
            case .moveItem(let sourceIndexPath, let destinationIndexPath):
                self?.listItemsTable.isUserInteractionEnabled = false
                self?.moveItem(from: sourceIndexPath, to: destinationIndexPath)
                
            case .removeItem(let indexPath):
                self?.listItemsTable.isUserInteractionEnabled = false
                self?.removeItem(index: indexPath)
                
            default:
                return
            }
        }
    }
    
    private func reloadItem(index: [IndexPath], animated: Bool) {
        listItemsTable.performBatchUpdates {
            listItemsTable.reloadRows(at: index, with: animated ? .automatic : .none)
        } completion: {_ in
            self.listItemsTable.isUserInteractionEnabled = true
            self.viewModel.tableFinishedUpdating()
        }
    }
    
    private func insertItem(index: IndexPath) {
        listItemsTable.performBatchUpdates {
            listItemsTable.insertRows(at: [index], with: .bottom)
        } completion: {_ in
            self.listItemsTable.reloadData()
            self.listItemsTable.isUserInteractionEnabled = true
            self.viewModel.tableFinishedUpdating()
        }
    }
    
    private func moveItem(from oldRow: IndexPath, to newRow: IndexPath) {
        listItemsTable.performBatchUpdates {
            listItemsTable.moveRow(at: oldRow, to: newRow)
        } completion: {_ in
            self.listItemsTable.reloadData()
            self.listItemsTable.isUserInteractionEnabled = true
            self.viewModel.tableFinishedUpdating()
        }
    }
    
    private func removeItem(index: IndexPath) {
        listItemsTable.performBatchUpdates {
            listItemsTable.deleteRows(at: [index], with: .top)
        } completion: {_ in
            self.listItemsTable.reloadData()
            self.listItemsTable.isUserInteractionEnabled = true
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
            let sortButton = setMenuButton() //UIButton()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sortButton)
        }
    }
    
    private func setMenuButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(
            UIImage(named: "buttonMenu")?.withTintColor(.buttonBgrPrimary,
                                                        renderingMode: .alwaysOriginal), for: .normal)
        
//        let option1 = UIAction(title: .dropdownShare, image: UIImage(systemName: "square.and.arrow.up")) { _ in
//            
//        }
        
        let option2 = UIAction(title: .dropdownSorting, image: UIImage(systemName: "arrow.up.arrow.down")) { _ in
            self.viewModel.sortButtonPressed()
        }
        
        let option3 = UIAction(title: .dropdownDuplicate, image: UIImage(systemName: "plus.square.on.square")) { _ in
            self.viewModel.duplicateButtonPressed()
        }
        
        let option4 = UIAction(title: .dropdownRemind, image: UIImage(systemName: "bell")) { _ in
            self.viewModel.addNoticeButtonPressed()
        }
        
        let menu = UIMenu(children: [option2, option3, option4]) //option1
        
        
        // Настраиваем кнопку
        button.menu = menu
        button.showsMenuAsPrimaryAction = true // Открывает меню по тапу, а не по долгому нажатию
        
        return button
    }
    
    private func showPopUpView(for itemID: UUID, quantity: Float, unit: Units) {
        let popUpView = PopUpAssembler().build(itemID: itemID, delegate: self.viewModel as? PopUpVCDelegate, quantity: quantity, unit: unit)
        if let sheet = popUpView.sheetPresentationController {
            let detent: UISheetPresentationController.Detent = .custom(identifier: .init(rawValue: "custom")) { _ in 224 }
            sheet.detents = [detent]
            sheet.preferredCornerRadius = 24
            sheet.prefersGrabberVisible = true
        }
        
        present(popUpView, animated: true)
    }
    
    private func addReminder() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)
        alert.view.heightAnchor.constraint(equalToConstant: 400).isActive = true
        alert.view.backgroundColor = .white
        alert.view.layer.cornerRadius = 16
        alert.view.clipsToBounds = true
        
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor).isActive = true
        datePicker.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor).isActive = true
        datePicker.topAnchor.constraint(equalTo: alert.view.topAnchor).isActive = true
        datePicker.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -90).isActive = true

        let okAction = UIAlertAction(title: .buttonDone, style: .default) { _ in
            self.viewModel.addEventAndNotification(date: self.datePicker.date)
        }
        let cancelAction = UIAlertAction(title: .buttonCancel, style: .destructive)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
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
            cell.delegate = viewModel as? ShoppingListCellDelegate
            cell.configure(with: cellParams.1)
            return cell
            
        case .button:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ShoppingListCellButton.reuseIdentifier,
                for: indexPath
            ) as? ShoppingListCellButton else {
                return UITableViewCell()
            }
            cell.delegate = viewModel as? ShoppingListCellDelegate
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
        viewModel.isDropAllowed(for: indexPath.row)
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
        
        let isdropAllowed = viewModel.isDropAllowed(for: destinationIndexPath?.row ?? viewModel.getTableRowCount() - 1)
        
        return session.items.count == 1 && tableView.hasActiveDrag && isdropAllowed
        ? UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        : UITableViewDropProposal(operation: .cancel)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
    }
}
