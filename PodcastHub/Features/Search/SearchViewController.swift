import UIKit

final class SearchViewController: UIViewController {
    private enum Section {
        case results
    }

    private let viewModel: SearchViewModelProtocol
    private lazy var tableView = UITableView(frame: .zero, style: .insetGrouped)
    private lazy var dataSource = makeDataSource()
    private let searchController = UISearchController(searchResultsController: nil)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    init(viewModel: SearchViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "Tìm kiếm"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) chưa được hỗ trợ")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindViewModel()
    }

    private func setupViews() {
        view.backgroundColor = .systemGroupedBackground
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(HomeShowCell.self, forCellReuseIdentifier: HomeShowCell.reuseIdentifier)
        tableView.delegate = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        loadingIndicator.hidesWhenStopped = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingIndicator)
    }

    private func bindViewModel() {
        viewModel.onResultsChanged = { [weak self] shows in
            self?.applySnapshot(shows: shows)
        }
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            guard let self else {
                return
            }
            if isLoading {
                loadingIndicator.startAnimating()
            } else {
                loadingIndicator.stopAnimating()
            }
        }
        viewModel.onError = { [weak self] message in
            self?.presentError(message: message)
        }
    }

    private func makeDataSource() -> UITableViewDiffableDataSource<Section, Show> {
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

    private func applySnapshot(shows: [Show]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Show>()
        snapshot.appendSections([.results])
        snapshot.appendItems(shows)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func presentError(message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(alert, animated: true)
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearchQuery(searchController.searchBar.text ?? "")
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let show = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        viewModel.didSelectShow(show)
    }
}
