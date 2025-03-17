//
//  LanguageCell.swift
//  ShoppingList
//
//  Created by Andrey Zhelev on 13.03.2025.
//
import UIKit

class LanguageCell: UITableViewCell {
    
    // Идентификатор ячейки
    static let reuseIdentifier = "LanguageCell"
    
    // Название языка
    private let languageLabel: UILabel = {
        let label = UILabel()
        label.font = .settingsItem
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Инициализатор
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Настройка интерфейса
    private func setupUI() {
        self.backgroundColor = .gray.withAlphaComponent(0.05)
        self.selectionStyle = .none
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 10
        
        contentView.addSubview(languageLabel)
        
        NSLayoutConstraint.activate([
            languageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            languageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            languageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            languageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with params: LanguageCellParams) {
        
        languageLabel.text = params.name
        accessoryType = params.isSelected ? .checkmark : .none
                
        switch params.corners {
        case .top:
            self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        case .bottom:
            self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        case .all:
            self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        case .none:
            self.layer.maskedCorners = []
        }
        
        separatorInset = params.separator
        ? UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        : UIEdgeInsets(top: 0, left: self.bounds.width + 40, bottom: 0, right: 0)
    }
}
