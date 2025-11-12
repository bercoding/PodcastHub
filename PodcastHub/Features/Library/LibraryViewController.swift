import FirebaseAuth
import UIKit

final class LibraryViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case saved = 0
        case favorites = 1
        case downloaded = 2
        
        var title: String {
            switch self {
            case .saved: return "Đã lưu"
            case .favorites: return "Yêu thích"
            case .downloaded: return "Đã tải về"
            }
        }
        
        var icon: String {
            switch self {
            case .saved: return "bookmark.fill"
            case .favorites: return "heart.fill"
            case .downloaded: return "arrow.down.circle.fill"
            }
        }
    }
    
    private lazy var tableView = UITableView(frame: .zero, style: .insetGrouped)
    private lazy var dataSource = makeDataSource()
    private let headerView = LibraryHeaderView()
    private let authService = AuthService()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupHeader()
        setupAuthListener()
        applyInitialSnapshot()
        updateUserState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let handle = authStateHandle {
            authService.removeStateDidChangeListener(handle)
        }
    }
    
    private func setupViews() {
        view.backgroundColor = .systemGroupedBackground
        title = "Thư viện"
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.register(LibraryCategoryCell.self, forCellReuseIdentifier: LibraryCategoryCell.reuseIdentifier)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupHeader() {
        headerView.onLoginTapped = { [weak self] in
            self?.handleLoginTapped()
        }
        updateHeaderLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderLayout()
    }
    
    private func updateHeaderLayout() {
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 80)
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        tableView.tableHeaderView = headerView
    }
    
    private func makeDataSource() -> UITableViewDiffableDataSource<Int, Section> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, section -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: LibraryCategoryCell.reuseIdentifier,
                for: indexPath
            )
            if let cell = cell as? LibraryCategoryCell {
                cell.configure(
                    title: section.title,
                    icon: section.icon,
                    count: self.getCount(for: section)
                )
            }
            return cell
        }
    }
    
    private func applyInitialSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Section>()
        snapshot.appendSections([0])
        snapshot.appendItems(Section.allCases, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func getCount(for section: Section) -> Int {
        // TODO: Lấy số lượng thực tế từ Realm/Firestore
        switch section {
        case .saved: return 0
        case .favorites: return 0
        case .downloaded: return 0
        }
    }
    
    private func setupAuthListener() {
        authStateHandle = authService.addStateDidChangeListener { [weak self] user in
            self?.updateUserState()
        }
    }
    
    private func updateUserState() {
        let isLoggedIn = authService.isAuthenticated
        let userName = authService.currentUser?.email?.components(separatedBy: "@").first
        headerView.updateUserState(isLoggedIn: isLoggedIn, userName: userName)
    }
    
    private func handleLoginTapped() {
        if authService.isAuthenticated {
            // Hiển thị profile hoặc đăng xuất
            showProfileMenu()
        } else {
            // Hiển thị màn đăng nhập
            showLoginScreen()
        }
    }
    
    private func showLoginScreen() {
        let alert = UIAlertController(
            title: "Đăng nhập",
            message: "Nhập email và mật khẩu",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Mật khẩu"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Đăng nhập", style: .default) { [weak self] _ in
            guard let self,
                  let email = alert.textFields?[0].text,
                  let password = alert.textFields?[1].text,
                  !email.isEmpty, !password.isEmpty else { return }
            
            Task {
                do {
                    _ = try await self.authService.signIn(email: email, password: password)
                    await MainActor.run {
                        self.updateUserState()
                    }
                } catch {
                    await MainActor.run {
                        self.presentError(message: error.localizedDescription)
                    }
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Đăng ký", style: .default) { [weak self] _ in
            guard let self,
                  let email = alert.textFields?[0].text,
                  let password = alert.textFields?[1].text,
                  !email.isEmpty, !password.isEmpty else { return }
            
            Task {
                do {
                    _ = try await self.authService.signUp(email: email, password: password)
                    await MainActor.run {
                        self.updateUserState()
                    }
                } catch {
                    await MainActor.run {
                        self.presentError(message: error.localizedDescription)
                    }
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showProfileMenu() {
        let alert = UIAlertController(
            title: authService.currentUser?.email ?? "Tài khoản",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Đăng xuất", style: .destructive) { [weak self] _ in
            do {
                try self?.authService.signOut()
                self?.updateUserState()
            } catch {
                self?.presentError(message: error.localizedDescription)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        present(alert, animated: true)
    }
    
    private func presentError(message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(alert, animated: true)
    }
}

extension LibraryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let category = dataSource.itemIdentifier(for: indexPath) else { return }
        
        // TODO: Navigate to detail screen for each category
        let alert = UIAlertController(
            title: category.title,
            message: "Danh sách \(category.title.lowercased()) đang được cập nhật",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        0
    }
}

