import UIKit

final class ShowDetailViewController: UIViewController {
    private enum Section {
        case main
    }

    private let viewModel: ShowDetailViewModelProtocol
    private lazy var tableView = UITableView(frame: .zero, style: .plain)
    private lazy var dataSource = makeDataSource()
    private let headerView = ShowDetailHeaderView()
    private var showArtworkURL: URL?

    init(viewModel: ShowDetailViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) chưa được hỗ trợ")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindViewModel()
        viewModel.load()
    }

    private func setupViews() {
        view.backgroundColor = .systemGroupedBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(EpisodeCell.self, forCellReuseIdentifier: EpisodeCell.reuseIdentifier)
        tableView.delegate = self
        // đảm bảo header có width bằng tableView để AutoLayout tính đúng chiều cao
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 1)
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func bindViewModel() {
        viewModel.onShowLoaded = { [weak self] show in
            self?.title = show.title
            self?.headerView.configure(with: show)
            self?.showArtworkURL = show.imageURL
            // cập nhật lại kích thước header sau khi set nội dung
            self?.updateHeaderLayout()
        }
        viewModel.onEpisodesChanged = { [weak self] episodes in
            self?.applySnapshot(episodes: episodes)
        }
        viewModel.onError = { [weak self] message in
            self?.presentError(message: message)
        }
    }

    private func makeDataSource() -> UITableViewDiffableDataSource<Section, Episode> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, episode -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: EpisodeCell.reuseIdentifier,
                for: indexPath
            )
            if let cell = cell as? EpisodeCell {
                cell.configure(with: episode)
            }
            return cell
        }
    }

    private func applySnapshot(episodes: [Episode]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Episode>()
        snapshot.appendSections([.main])
        snapshot.appendItems(episodes)
        dataSource.apply(snapshot, animatingDifferences: true)
        updateHeaderLayout()
    }

    private func updateHeaderLayout() {
        // cập nhật width trước khi tính kích thước phù hợp
        if var headerFrame = tableView.tableHeaderView?.frame {
            headerFrame.size.width = tableView.bounds.width
            tableView.tableHeaderView?.frame = headerFrame
        }
        guard let header = tableView.tableHeaderView else {
            return
        }
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let height = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        if header.frame.height != height {
            header.frame.size.height = height
            tableView.tableHeaderView = header
        }
    }

    private func presentError(message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(alert, animated: true)
    }
}

extension ShowDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let episode = dataSource.itemIdentifier(for: indexPath), let url = episode.audioURL else {
            presentError(message: "Không có URL audio hợp lệ.")
            return
        }
        let playerVC = PlayerViewController(
            episodeTitle: episode.title,
            artworkURL: episode.thumbnailURL ?? showArtworkURL,
            audioURL: url
        )
        playerVC.modalPresentationStyle = .fullScreen
        present(playerVC, animated: true)
    }
}

final class ShowDetailHeaderView: UIView {
    private let imageView = UIImageView()
    private let publisherLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let subscribeButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func configure(with show: Show) {
        imageView.image = UIImage(systemName: "waveform.circle.fill")
        publisherLabel.text = show.publisher
        descriptionLabel.text = show.description
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        configureImageView()
        configureLabels()
        configureSubscribeButton()

        let stack = UIStackView(arrangedSubviews: [
            imageView,
            publisherLabel,
            descriptionLabel,
            subscribeButton
        ])
        configureStackView(stack)
    }

    private func configureImageView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
        imageView.tintColor = .systemBlue
        // Chỉ đặt tỉ lệ 16:9 dựa trên chính width của imageView để tránh thiếu common ancestor
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 9.0 / 16.0)
            .isActive = true
    }

    private func configureLabels() {
        publisherLabel.font = .preferredFont(forTextStyle: .subheadline)
        publisherLabel.textColor = .secondaryLabel
        publisherLabel.translatesAutoresizingMaskIntoConstraints = false

        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.numberOfLines = 4
        descriptionLabel.lineBreakMode = .byTruncatingTail
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureSubscribeButton() {
        subscribeButton.setTitle("Theo dõi", for: .normal)
        subscribeButton.translatesAutoresizingMaskIntoConstraints = false
        subscribeButton.layer.cornerRadius = 10
        subscribeButton.layer.cornerCurve = .continuous
        subscribeButton.backgroundColor = .systemBlue
        subscribeButton.setTitleColor(.white, for: .normal)
        subscribeButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        subscribeButton.setContentHuggingPriority(.required, for: .horizontal)
        subscribeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func configureStackView(_ stack: UIStackView) {
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.setCustomSpacing(16, after: descriptionLabel)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])

        // Đảm bảo label wrap đúng chiều rộng
        descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        descriptionLabel.setContentHuggingPriority(.required, for: .vertical)
    }
}

final class EpisodeCell: UITableViewCell {
    static let reuseIdentifier = "EpisodeCell"

    private let titleLabel = UILabel()
    private let detailLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func configure(with episode: Episode) {
        titleLabel.text = episode.title
        let duration = DateComponentsFormatter.podcastDuration.string(from: TimeInterval(episode.duration))
        let dateText: String = if let publishDate = episode.publishDate {
            DateFormatter.podcastDate.string(from: publishDate)
        } else {
            ""
        }
        detailLabel.text = [duration, dateText]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
    }

    private func setupViews() {
        accessoryType = .disclosureIndicator
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailLabel.textColor = .secondaryLabel
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
}

extension DateComponentsFormatter {
    static let podcastDuration: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()
}

extension DateFormatter {
    static let podcastDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
