import UIKit

final class LibraryCategoryCell: UITableViewCell {
    static let reuseIdentifier = "LibraryCategoryCell"
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let stackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        accessoryType = .disclosureIndicator
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.textColor = .label
        
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = .preferredFont(forTextStyle: .subheadline)
        countLabel.textColor = .secondaryLabel
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(UIView()) // Spacer
        stackView.addArrangedSubview(countLabel)
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(title: String, icon: String, count: Int) {
        iconImageView.image = UIImage(systemName: icon)
        titleLabel.text = title
        countLabel.text = count > 0 ? "\(count)" : ""
    }
}

