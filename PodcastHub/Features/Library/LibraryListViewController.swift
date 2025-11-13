import UIKit

final class LibraryListViewController: UIViewController {
    enum LibraryCategory {
        case saved
        case favorites
        case downloaded

        var title: String {
            switch self {
            case .saved: "Đã lưu"
            case .favorites: "Yêu thích"
            case .downloaded: "Đã tải về"
            }
        }
    }

    private let category: LibraryCategory
    private let libraryService = LibraryService.shared
    private lazy var tableView = UITableView(frame: .zero, style: .insetGrouped)
    private lazy var dataSource = makeDataSource()
    private var shows: [Show] = []
    private var emptyStateLabel: UILabel?

    init(category: LibraryCategory) {
        self.category = category
        super.init(nibName: nil, bundle: nil)
        title = category.title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadShows()
        setupObserver()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadShows()
    }

    private func setupViews() {
        view.backgroundColor = .systemGroupedBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(HomeShowCell.self, forCellReuseIdentifier: HomeShowCell.reuseIdentifier)
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(libraryUpdated),
            name: NSNotification.Name("LibraryUpdated"),
            object: nil
        )
    }

    @objc private func libraryUpdated() {
        loadShows()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func loadShows() {
        do {
            switch category {
            case .saved:
                shows = try libraryService.getSavedShows()
            case .favorites:
                shows = try libraryService.getFavoritedShows()
            case .downloaded:
                shows = try libraryService.getDownloadedShows()
            }
            applySnapshot()
        } catch {
            presentError(message: "Lỗi khi tải danh sách: \(error.localizedDescription)")
        }
    }

    private func makeDataSource() -> UITableViewDiffableDataSource<Int, Show> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, show -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: HomeShowCell.reuseIdentifier,
                for: indexPath
            )
            if let cell = cell as? HomeShowCell {
                cell.configure(with: show)
            }
            return cell
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Show>()
        snapshot.appendSections([0])
        snapshot.appendItems(shows)
        dataSource.apply(snapshot, animatingDifferences: true)

        if shows.isEmpty {
            showEmptyState()
        } else {
            hideEmptyState()
        }
    }

    private func showEmptyState() {
        if emptyStateLabel == nil {
            let emptyLabel = UILabel()
            emptyLabel.text = "Chưa có nội dung nào"
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.font = .systemFont(ofSize: 17, weight: .medium)
            emptyLabel.textAlignment = .center
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(emptyLabel)
            NSLayoutConstraint.activate([
                emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            emptyStateLabel = emptyLabel
        }
        emptyStateLabel?.isHidden = false
    }

    private func hideEmptyState() {
        emptyStateLabel?.isHidden = true
    }

    private func presentError(message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(alert, animated: true)
    }
}

extension LibraryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let show = dataSource.itemIdentifier(for: indexPath) else { return }

        // Navigate to ShowDetailViewController
        let repository = AppDependencyContainer().makePodcastRepository()
        let viewModel = ShowDetailViewModel(repository: repository, showId: show.id)
        let detailVC = ShowDetailViewController(viewModel: viewModel)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
