import UIKit

final class ShoppingListViewController: UIViewController, KeyboardHandler {

    // MARK: - Public Properties
    var keyboardObserverTokens: [NSObjectProtocol] = []
    var keyboardWillHideAction: ((Notification) -> Void)?
    var keyboardWillShowAction: ((Notification) -> Void)?

    // MARK: - Private Properties
    private lazy var checkAllSwitch = {
        let switchView = UISwitch()
        switchView.addTarget(self, action: #selector(checkAllSwitchValueChanged), for: .valueChanged)
        return switchView
    }()

    private lazy var checkAllSwitchBlock = {
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

    private var pendingScrollIndexPath: IndexPath?
    private let viewModel: ShoppingListViewModelProtocol

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
        setupKeyboardActions()
        setupKeyboardHandling()
        bindViewModel()
        setUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear()
    }

    deinit {
        removeKeyboardHandling()
    }

    // MARK: - Private Methods
    private func bindViewModel() {
        viewModel.shoppingListBinding.bind { [weak self] value in
            switch value {
            case .showPopUp(let id, let quantity, let unit):
                self?.showPopUpView(for: id, quantity: quantity, unit: unit)

            case .reloadTable:
                self?.listItemsTable.reloadData()

            case .updateItems(let indexPath, let option):
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

            case .updateBottomButton(let isEnabled):
                self?.updateBottomButton(isEnabled: isEnabled)

            case .updateCheckAllAvailability(let isEnabled):
                self?.checkAllSwitch.isEnabled = isEnabled

            case .updateCheckAllSwitch(let isOn):
                self?.checkAllSwitch.setOn(isOn, animated: true)

            default:
                return
            }
        }
    }

    private func reloadItem(index: [IndexPath], animated: Bool) {
        listItemsTable.performBatchUpdates {
            listItemsTable.reloadRows(at: index, with: animated ? .automatic : .none)
        } completion: { _ in
            self.listItemsTable.isUserInteractionEnabled = true
            self.viewModel.tableFinishedUpdating()
        }
    }

    private func insertItem(index: IndexPath) {
        pendingScrollIndexPath = index
        listItemsTable.performBatchUpdates {
            listItemsTable.insertRows(at: [index], with: .bottom)
        } completion: { _ in
            self.listItemsTable.isUserInteractionEnabled = true
            self.viewModel.tableFinishedUpdating()
            self.scrollToPendingItem(animated: true)
        }
    }

    private func moveItem(from oldRow: IndexPath, to newRow: IndexPath) {
        listItemsTable.performBatchUpdates {
            listItemsTable.moveRow(at: oldRow, to: newRow)
        } completion: { _ in
            self.listItemsTable.reloadData()
            self.listItemsTable.isUserInteractionEnabled = true
            self.viewModel.tableFinishedUpdating()
        }
    }

    private func removeItem(index: IndexPath) {
        listItemsTable.performBatchUpdates {
            listItemsTable.deleteRows(at: [index], with: .top)
        } completion: { _ in
            self.listItemsTable.reloadData()
            self.listItemsTable.isUserInteractionEnabled = true
            self.viewModel.tableFinishedUpdating()
        }
    }

    private func setUI() {
        self.view.backgroundColor = .screenBgrPrimary
        navBarConfig()
        navigationController?.setNavigationBarHidden(false, animated: true)

        [checkAllSwitchBlock, bottomButton, listItemsTable].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        if viewModel.listIsCompleted() {
            checkAllSwitchBlock.isHidden = true
            checkAllSwitchBlock.heightAnchor.constraint(equalToConstant: 0).isActive = true
        } else {
            checkAllSwitchBlock.isHidden = false
            checkAllSwitchBlock.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }

        updateBottomButton(isEnabled: viewModel.getBottomButtonState())
        checkAllSwitch.isEnabled = viewModel.getCheckAllSwitchAvailability()
        checkAllSwitch.setOn(viewModel.getCheckAllSwitchState(), animated: false)

        NSLayoutConstraint.activate([
            checkAllSwitchBlock.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            checkAllSwitchBlock.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            checkAllSwitchBlock.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            listItemsTable.topAnchor.constraint(equalTo: checkAllSwitchBlock.bottomAnchor, constant: 20),
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
            let sortButton = setMenuButton()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sortButton)
        }
    }

    private func scrollToPendingItem(animated: Bool) {
        guard let indexPath = pendingScrollIndexPath,
              indexPath.row < viewModel.getTableRowCount() else {
            return
        }

        listItemsTable.layoutIfNeeded()
        listItemsTable.scrollToRow(at: indexPath, at: .middle, animated: animated)
    }

    private func setupKeyboardActions() {
        keyboardWillShowAction = { [weak self] notification in
            guard let self,
                  let userInfo = notification.userInfo,
                  let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                  let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
                return
            }

            let keyboardFrameInView = self.view.convert(keyboardFrame, from: nil)
            let overlap = self.view.bounds.intersection(keyboardFrameInView).height
            UIView.animate(withDuration: duration) {
                self.listItemsTable.contentInset.bottom = overlap
                self.listItemsTable.verticalScrollIndicatorInsets = UIEdgeInsets(
                    top: 0,
                    left: 0,
                    bottom: overlap,
                    right: 0
                )
                self.scrollToPendingItem(animated: false)
            } completion: { _ in
                self.pendingScrollIndexPath = nil
            }
        }

        keyboardWillHideAction = { [weak self] notification in
            guard let self,
                  let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
                    as? TimeInterval else {
                return
            }

            UIView.animate(withDuration: duration) {
                self.listItemsTable.contentInset = .zero
                self.listItemsTable.verticalScrollIndicatorInsets = .zero
            }
        }
    }

    private func updateBottomButton(isEnabled: Bool) {
        bottomButton.isEnabled = isEnabled
        bottomButton.backgroundColor = isEnabled ? .buttonBgrTertiary : .buttonBgrDisabled
        bottomButton.setTitleColor(isEnabled ? .buttonTextPrimary : .buttonTextSecondary, for: .normal)
    }

    private func setMenuButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(
            UIImage(named: "buttonMenu")?.withTintColor(.buttonBgrPrimary,
                                                        renderingMode: .alwaysOriginal), for: .normal)

        let sortAction = UIAction(title: .dropdownSorting, image: UIImage(systemName: "arrow.up.arrow.down")) { _ in
            self.viewModel.sortButtonPressed()
        }

        let duplicateAction = UIAction(title: .dropdownDuplicate, image: UIImage(systemName: "plus.square.on.square")) { _ in
            self.viewModel.duplicateButtonPressed()
        }

        let reminderAction = UIAction(title: .dropdownRemind, image: UIImage(systemName: "bell")) { _ in
            self.viewModel.addNoticeButtonPressed()
        }

        let menu = UIMenu(children: [sortAction, duplicateAction, reminderAction])

        button.menu = menu
        button.showsMenuAsPrimaryAction = true

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

        guard !viewModel.listIsCompleted(), indexPath.row != viewModel.getTableRowCount() - 1 else {
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

    func tableView(
        _ tableView: UITableView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UITableViewDropProposal {

        let isDropAllowed = viewModel.isDropAllowed(for: destinationIndexPath?.row ?? viewModel.getTableRowCount() - 1)

        return session.items.count == 1 && tableView.hasActiveDrag && isDropAllowed
        ? UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        : UITableViewDropProposal(operation: .cancel)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
    }
}
