import UIKit

class DatePickerView: UIView {
    
    private let viewModel: DatePickerViewModel
    
    init(viewModel: DatePickerViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func confirmButtonTapped() {
        viewModel.confirmAction(date: datePicker.date)
    }
    
    @objc private func cancelButtonTapped() {
        viewModel.cancelAction()
    }
    
    private func createLabel(text: String, font: UIFont, numberOfLines: Int) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = .textColorPrimary
        label.textAlignment = .center
        label.numberOfLines = numberOfLines
        return label
    }
    
    private lazy var datePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.minimumDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())
        datePicker.maximumDate = Calendar.current.date(byAdding: .day, value: 365, to: Date())
        datePicker.roundsToMinuteInterval = true
        datePicker.minuteInterval = 5
        datePicker.preferredDatePickerStyle = .wheels
        return datePicker
    }()
    
    private func createButton(title: String, cancelMode: Bool, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(cancelMode ? .white : .buttonTextPrimary, for: .normal)
        button.backgroundColor = cancelMode ? .buttonBgrSecondary : .buttonBgrTertiary
        button.titleLabel?.font = .listScreenTitle
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func createStackView(arrangedSubviews: [UIView], spacing: CGFloat = 0) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .vertical
        stackView.distribution = .equalCentering
        stackView.spacing = spacing
        return stackView
    }
    
    private func setupView() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        let datePickerStack = createStackView(
            arrangedSubviews: [
                createLabel(text: viewModel.titleLabel, font: .popUpTitle, numberOfLines: 1),
                datePicker
            ],
            spacing: 12
        )
        
        let datePickerStackView = UIView()
        datePickerStackView.backgroundColor = .screenBgrPrimary
        datePickerStackView.layer.cornerRadius = 16
        datePickerStackView.clipsToBounds = true
        datePickerStackView.addSubview(datePickerStack)
        datePickerStack.translatesAutoresizingMaskIntoConstraints = false
  
        let confirmButton = createButton(
            title: viewModel.confirmButtonTitle,
            cancelMode: false,
            action: #selector(confirmButtonTapped)
        )
        
        let cancelButton = createButton(
            title: viewModel.cancelButtonTitle,
            cancelMode: true,
            action: #selector(cancelButtonTapped)
        )
        
        let buttonStack = createStackView(arrangedSubviews: [confirmButton, cancelButton], spacing: 10)
        
        let mainStackView = createStackView(arrangedSubviews: [datePickerStackView, buttonStack], spacing: 16)
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            datePickerStackView.widthAnchor.constraint(equalTo: mainStackView.widthAnchor),
            datePickerStack.leadingAnchor.constraint(equalTo: datePickerStackView.leadingAnchor),
            datePickerStack.trailingAnchor.constraint(equalTo: datePickerStackView.trailingAnchor),
            datePickerStack.topAnchor.constraint(equalTo: datePickerStackView.topAnchor, constant: 16),
            datePickerStack.bottomAnchor.constraint(equalTo: datePickerStackView.bottomAnchor, constant: -16),
            buttonStack.widthAnchor.constraint(equalTo: mainStackView.widthAnchor),
            confirmButton.heightAnchor.constraint(equalToConstant: 48),
            cancelButton.heightAnchor.constraint(equalTo: confirmButton.heightAnchor)
        ])
    }
}


