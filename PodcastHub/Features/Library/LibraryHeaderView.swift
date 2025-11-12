import UIKit

final class LibraryHeaderView: UIView {
    private let loginButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    
    var onLoginTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .systemGroupedBackground
        
        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Thư viện của bạn"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.textColor = .label
        addSubview(titleLabel)
        
        // Login Button
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
        loginButton.tintColor = .label
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        loginButton.contentHorizontalAlignment = .fill
        loginButton.contentVerticalAlignment = .fill
        addSubview(loginButton)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            loginButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            loginButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            loginButton.widthAnchor.constraint(equalToConstant: 44),
            loginButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func updateUserState(isLoggedIn: Bool, userName: String? = nil) {
        if isLoggedIn, let userName = userName {
            loginButton.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
            loginButton.tintColor = .systemBlue
            titleLabel.text = "Xin chào, \(userName)"
        } else {
            loginButton.setImage(UIImage(systemName: "person.circle"), for: .normal)
            loginButton.tintColor = .label
            titleLabel.text = "Thư viện của bạn"
        }
    }
    
    @objc private func didTapLogin() {
        onLoginTapped?()
    }
}

