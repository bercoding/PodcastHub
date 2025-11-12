//
//  HomeViewController.swift
//  PodcastHub
//
//  Created by Le Thanh Nhan on 10/11/25.
//

import UIKit

final class HomeViewController: UIViewController {
    private enum Section {
        case main
    }

    private let viewModel: HomeViewModelProtocol
    private lazy var tableView = UITableView(frame: .zero, style: .insetGrouped)
    private lazy var dataSource = makeDataSource()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    init(viewModel: HomeViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "Khám phá"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) chưa được hỗ trợ")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindViewModel()
        viewModel.loadTrending()
    }

    private func setupViews() {
        view.backgroundColor = .systemGroupedBackground
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
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func bindViewModel() {
        viewModel.onShowsChanged = { [weak self] shows in
            self?.applySnapshot(with: shows)
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

    private func applySnapshot(with shows: [Show]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Show>()
        snapshot.appendSections([.main])
        snapshot.appendItems(shows)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func presentError(message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(alert, animated: true)
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let show = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        viewModel.didSelectShow(show)
    }
}
