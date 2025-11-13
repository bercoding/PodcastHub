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

        // Configure table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(HomeShowCell.self, forCellReuseIdentifier: HomeShowCell.reuseIdentifier)
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)

        // Pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .systemBlue
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func refreshData() {
        viewModel.loadTrending()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.tableView.refreshControl?.endRefreshing()
        }
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
        guard let show = dataSource.itemIdentifier(for: indexPath) else {
            return
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Animate selection
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.1, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    cell.transform = .identity
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tableView.deselectRow(at: indexPath, animated: true)
            self.viewModel.didSelectShow(show)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        120
    }
}
