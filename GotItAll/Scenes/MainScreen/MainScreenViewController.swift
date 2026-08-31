import UIKit

final class MainScreenViewController: UIViewController {

    // MARK: - Private Properties
    private lazy var addNewListButton = {
        let button = UIButton()
        button.setTitle(.buttonCreateNewList, for: .normal)
        button.setTitleColor(.buttonTextPrimary, for: .normal)
        button.titleLabel?.font = .listScreenTitle
        button.backgroundColor = .buttonBgrTertiary
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(addNewListButtonPressed), for: .touchUpInside)
        return button
    }()

    private let backgroundImageView = UIImageView(image: UIImage(named: "listBgrImage"))
    private var clearArchiveButtonHeightConstraint = NSLayoutConstraint()

    private lazy var clearArchiveButton = {
        let button = UIButton()
        button.setTitle(.buttonClearArchive, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .listScreenTitle
        button.backgroundColor = .buttonBgrSecondary
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(clearArchiveButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var shoppingListsTable = {
        let table = UITableView()
        table.register(ShoppingListsTableCell.self, forCellReuseIdentifier: ShoppingListsTableCell.reuseIdentifier)
        table.dataSource = self
        table.delegate = self
        table.backgroundColor = .clear
        table.separatorColor = .tableSeparator
        table.separatorStyle = .singleLine
        table.showsVerticalScrollIndicator = false
        return table
    }()

    private let titleLabel = {
        let label = UILabel()
        label.textColor = .textColorPrimary
        label.font = .mainScreenTitle
        label.textAlignment = .left
        label.numberOfLines = 2
        return label
    }()

    private let viewModel: MainScreenViewModelProtocol

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
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.viewWillAppear()
        updateClearArchiveButtonState()
    }

    // MARK: - Private Methods
    private func bindViewModel() {
        viewModel.mainScreenBinding.bind { [weak self] value in
            switch value {
            case .reloadTable:
                self?.shoppingListsTable.reloadData()
            case .removeItems(let indexPaths):
                self?.removeItems(at: indexPaths)
            default:
                break
            }
        }
    }

    private func removeItems(at indexPaths: [IndexPath]) {
        shoppingListsTable.performBatchUpdates {
            shoppingListsTable.deleteRows(at: indexPaths, with: .top)
        } completion: { [weak self] _ in
            self?.shoppingListsTable.reloadData()
            self?.updateClearArchiveButtonState()
        }
    }

    private func setUI() {
        view.backgroundColor = .screenBgrPrimary
        titleLabel.text = viewModel.getScreenTitle()

        [titleLabel, backgroundImageView, addNewListButton, clearArchiveButton, shoppingListsTable].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        clearArchiveButton.isHidden = !viewModel.getClearArchiveButtonState()
        clearArchiveButtonHeightConstraint = clearArchiveButton.heightAnchor.constraint(
            equalToConstant: clearArchiveButton.isHidden ? 0 : 48
        )
        clearArchiveButtonHeightConstraint.isActive = true

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            addNewListButton.bottomAnchor.constraint(equalTo: clearArchiveButton.topAnchor, constant: -12),
            addNewListButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addNewListButton.heightAnchor.constraint(equalToConstant: 48),
            addNewListButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            addNewListButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            clearArchiveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            clearArchiveButton.centerXAnchor.constraint(equalTo: addNewListButton.centerXAnchor),
            clearArchiveButton.leadingAnchor.constraint(equalTo: addNewListButton.leadingAnchor),
            clearArchiveButton.trailingAnchor.constraint(equalTo: addNewListButton.trailingAnchor),

            backgroundImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 62),
            backgroundImageView.widthAnchor.constraint(equalTo: backgroundImageView.heightAnchor, multiplier: 250 / 113),
            backgroundImageView.bottomAnchor.constraint(equalTo: addNewListButton.topAnchor, constant: -16),

            shoppingListsTable.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            shoppingListsTable.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            shoppingListsTable.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            shoppingListsTable.bottomAnchor.constraint(equalTo: backgroundImageView.bottomAnchor)
        ])
    }

    private func updateClearArchiveButtonState() {
        let oldHeight = clearArchiveButtonHeightConstraint.constant
        clearArchiveButton.isHidden = !viewModel.getClearArchiveButtonState()
        let newHeight: CGFloat = clearArchiveButton.isHidden ? 0 : 48
        guard oldHeight != newHeight else {
            return
        }

        clearArchiveButtonHeightConstraint.constant = newHeight
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Actions
    @objc private func addNewListButtonPressed() {
        viewModel.addNewListButtonPressed()
    }

    @objc private func clearArchiveButtonPressed() {
        viewModel.clearArchiveButtonPressed()
    }
}

// MARK: - UITableViewDataSource
extension MainScreenViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ShoppingListsTableCell.reuseIdentifier,
            for: indexPath
        ) as? ShoppingListsTableCell else {
            debugPrint("@@@: Failed to prepare a table cell.")
            return UITableViewCell()
        }

        cell.configure(with: viewModel.getCellParams(for: indexPath.row))
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.getTableRowCount()
    }
}

// MARK: - UITableViewDelegate
extension MainScreenViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.listSelected(row: indexPath.row)
    }

    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: .buttonEdit) { [weak self] _, _, completion in
            self?.viewModel.editButtonPressed(in: indexPath.row)
            completion(true)
        }
        editAction.backgroundColor = .buttonBgrPrimary
        return viewModel.completeMode
        ? nil
        : UISwipeActionsConfiguration(actions: [editAction])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let primaryAction = UIContextualAction(
            style: .normal,
            title: viewModel.getPrimaryButtonTitle(for: indexPath.row)
        ) { [weak self] _, _, completion in
            self?.viewModel.primaryActionButtonPressed(in: indexPath.row)
            completion(true)
        }
        primaryAction.backgroundColor = .buttonBgrPrimary

        let deleteAction = UIContextualAction(style: .destructive, title: .buttonDelete) { [weak self] _, _, completion in
            self?.viewModel.deleteListButtonPressed(in: indexPath.row)
            completion(true)
        }
        deleteAction.backgroundColor = .buttonBgrSecondary

        return UISwipeActionsConfiguration(actions: [deleteAction, primaryAction])
    }
}
