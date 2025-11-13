import UIKit

final class ShowDetailViewController: UIViewController {
    private enum Section {
        case main
    }

    private let viewModel: ShowDetailViewModelProtocol
    private lazy var tableView = UITableView(frame: .zero, style: .plain)
    private lazy var dataSource = makeDataSource()
    private let headerView = ShowDetailHeaderView()
    private let headerContainerView = UIView()
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderLayout()
    }

    private func setupViews() {
        view.backgroundColor = .systemGroupedBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(EpisodeCell.self, forCellReuseIdentifier: EpisodeCell.reuseIdentifier)
        tableView.delegate = self
        // Đảm bảo tableView không có inset ảnh hưởng đến header
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never
        headerView.onLayoutChange = { [weak self] in
            self?.updateHeaderLayout()
        }
        // đảm bảo header có width bằng tableView để AutoLayout tính đúng chiều cao
        headerContainerView.backgroundColor = .clear
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            headerView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor)
        ])
        headerContainerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 1)
        tableView.tableHeaderView = headerContainerView
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
        let targetWidth = view.bounds.width
        var containerFrame = headerContainerView.frame
        if containerFrame.width != targetWidth {
            containerFrame.size.width = targetWidth
        }
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()

        let targetSize = CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height)
        let fittedHeight = headerView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        if containerFrame.height != fittedHeight {
            containerFrame.size.height = fittedHeight
        }

        headerContainerView.frame = containerFrame
        tableView.tableHeaderView = headerContainerView
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
    private let backgroundGradientLayer = CAGradientLayer()
    private let mainStack = UIStackView()
    private let artworkContainer = UIView()
    private let imageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let infoCard = UIView()
    private let titleLabel = UILabel()
    private let publisherLabel = UILabel()
    private let metaStack = UIStackView()
    private let chipsStack = UIStackView()
    private let descriptionLabel = UILabel()
    private let expandButton = UIButton(type: .system)
    private let downloadButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let favoriteContainer = UIView()
    private let favoriteButton = UIButton(type: .system)
    private let buttonStack = UIStackView()
    private let topButtonStack = UIStackView()
    private var isFavorite = false
    private var isDescriptionExpanded = false
    private var currentShow: Show?
    private let libraryService = LibraryService.shared
    var onLayoutChange: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = imageView.bounds
        // Gradient lấp đầy toàn bộ view, không bị giới hạn bởi layoutMargins
        backgroundGradientLayer.frame = bounds
        // Bo góc 4 cạnh cho header view
        layer.cornerRadius = 0
        layer.masksToBounds = false
        clipsToBounds = false

        // Cập nhật corner radius theo kích thước thực tế của nút để tránh méo
        let downloadCorner = downloadButton.bounds.height / 2
        downloadButton.layer.cornerRadius = downloadCorner
        downloadButton.layer.shadowPath = UIBezierPath(
            roundedRect: downloadButton.bounds,
            cornerRadius: downloadCorner
        ).cgPath

        let saveCorner = saveButton.bounds.height / 2
        saveButton.layer.cornerRadius = saveCorner
        saveButton.layer.shadowPath = UIBezierPath(
            roundedRect: saveButton.bounds,
            cornerRadius: saveCorner
        ).cgPath

        // Favorite button luôn tròn
        favoriteContainer.layer.cornerRadius = favoriteContainer.bounds.height / 2
    }

    func configure(with show: Show) {
        currentShow = show
        titleLabel.text = show.title
        publisherLabel.text = show.publisher
        descriptionLabel.text = show.description.isEmpty ? "Không có mô tả" : show.description
        isDescriptionExpanded = false
        updateDescriptionExpansion()

        // Load trạng thái hiện tại từ Core Data
        isFavorite = libraryService.isShowFavorited(show.id)
        updateFavoriteButton()
        updateButtonStates(show: show)

        configureMetaInfo(show: show)
        configureChips(with: show.genres)

        if let url = show.imageURL {
            loadImage(from: url)
        } else {
            applyPlaceholderArtwork()
            updateBackgroundGradient(using: .systemBlue)
        }
    }

    private func updateButtonStates(show: Show) {
        let isSaved = libraryService.isShowSaved(show.id)
        let isDownloaded = libraryService.isShowDownloaded(show.id)

        // Cập nhật UI của các nút dựa trên trạng thái
        saveButton.setTitle(isSaved ? "Đã lưu" : "Lưu", for: .normal)
        saveButton.backgroundColor = isSaved ? UIColor.systemGreen.withAlphaComponent(0.12) : UIColor
            .systemBlue.withAlphaComponent(0.12)
        saveButton.setTitleColor(isSaved ? .systemGreen : .systemBlue, for: .normal)

        downloadButton.setTitle(isDownloaded ? "Đã tải" : "Tải về", for: .normal)
        downloadButton.backgroundColor = isDownloaded ? UIColor.systemGreen : .systemBlue
    }

    private func configureMetaInfo(show: Show) {
        for view in metaStack.arrangedSubviews {
            metaStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        if show.totalEpisodes > 0 {
            metaStack.addArrangedSubview(makeMetaBadge(icon: "waveform", text: "\(show.totalEpisodes) tập"))
        }

        if let rss = show.rss, !rss.isEmpty {
            metaStack.addArrangedSubview(makeMetaBadge(icon: "link", text: "RSS"))
        }

        metaStack.isHidden = metaStack.arrangedSubviews.isEmpty
    }

    private func configureChips(with genres: [String]) {
        for view in chipsStack.arrangedSubviews {
            chipsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let cleanGenres = genres
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.rangeOfCharacter(from: .letters) != nil }
            .prefix(3)

        for genre in cleanGenres {
            chipsStack.addArrangedSubview(makeChipLabel(text: genre))
        }

        chipsStack.isHidden = chipsStack.arrangedSubviews.isEmpty
        let hasDescription = !(descriptionLabel.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        expandButton.isHidden = !hasDescription
    }

    private func loadImage(from url: URL) {
        applyPlaceholderArtwork()
        updateBackgroundGradient(using: .systemBlue)

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }

            if let error {
                print("⚠️ Lỗi load artwork: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.applyPlaceholderArtwork()
                    self.updateBackgroundGradient(using: .systemBlue)
                }
                return
            }

            guard let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.applyPlaceholderArtwork()
                    self.updateBackgroundGradient(using: .systemBlue)
                }
                return
            }

            DispatchQueue.main.async {
                UIView.transition(
                    with: self.imageView,
                    duration: 0.25,
                    options: .transitionCrossDissolve
                ) {
                    self.imageView.image = image
                    let averageColor = image.averageColor
                    self.updateBackgroundGradient(using: averageColor)
                }
            }
        }
        task.resume()
    }

    private func applyPlaceholderArtwork() {
        imageView.image = UIImage(systemName: "waveform.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.backgroundColor = .secondarySystemBackground
    }

    private func updateBackgroundGradient(using color: UIColor) {
        let adjusted = color.withAlphaComponent(0.6)
        let darker = color.darker(by: 0.25)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundGradientLayer.colors = [
            adjusted.cgColor,
            darker.cgColor
        ]
        backgroundGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        CATransaction.commit()
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 20, right: 20)
        backgroundColor = .clear
        // Đảm bảo gradient không bị clip
        clipsToBounds = false
        layer.masksToBounds = false
        // Cấu hình gradient layer để lấp đầy toàn bộ
        backgroundGradientLayer.frame = bounds
        backgroundGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(backgroundGradientLayer, at: 0)
        configureArtworkContainer()
        configureInfoCard()
        configureMainStack()
    }

    private func configureMainStack() {
        mainStack.axis = .vertical
        mainStack.alignment = .fill
        mainStack.spacing = 14
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(artworkContainer)
        mainStack.addArrangedSubview(infoCard)
        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }

    private func configureArtworkContainer() {
        artworkContainer.translatesAutoresizingMaskIntoConstraints = false
        artworkContainer.layer.cornerRadius = 20
        artworkContainer.layer.shadowColor = UIColor.black.cgColor
        artworkContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        artworkContainer.layer.shadowRadius = 16
        artworkContainer.layer.shadowOpacity = 0.2
        artworkContainer.layer.masksToBounds = false

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true

        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor
        ]
        gradientLayer.locations = [0.5, 1.0]
        imageView.layer.addSublayer(gradientLayer)

        artworkContainer.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: artworkContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: artworkContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: artworkContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: artworkContainer.bottomAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.68)
        ])
    }

    private func configureInfoCard() {
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        infoCard.backgroundColor = .secondarySystemBackground
        infoCard.layer.cornerRadius = 20
        infoCard.layer.cornerCurve = .continuous
        infoCard.layer.shadowColor = UIColor.black.cgColor
        infoCard.layer.shadowOffset = CGSize(width: 0, height: 8)
        infoCard.layer.shadowRadius = 20
        infoCard.layer.shadowOpacity = 0.15
        infoCard.layer.masksToBounds = false

        let contentStack = UIStackView(arrangedSubviews: [
            titleLabel,
            publisherLabel,
            metaStack,
            chipsStack,
            descriptionLabel,
            expandButton,
            topButtonStack,
            buttonStack
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        infoCard.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -20)
        ])

        configureTitleLabel()
        configurePublisherLabel()
        configureMetaStack()
        configureChipsStack()
        configureDescriptionLabel()
        configureExpandButton()
        configureButtons()
    }

    private func configureTitleLabel() {
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
    }

    private func configurePublisherLabel() {
        publisherLabel.font = .systemFont(ofSize: 16, weight: .medium)
        publisherLabel.textColor = .secondaryLabel
    }

    private func configureMetaStack() {
        metaStack.axis = .horizontal
        metaStack.alignment = .center
        metaStack.spacing = 10
        metaStack.distribution = .fillProportionally
    }

    private func configureChipsStack() {
        chipsStack.axis = .horizontal
        chipsStack.spacing = 8
        chipsStack.alignment = .leading
        chipsStack.distribution = .fillProportionally
    }

    private func configureDescriptionLabel() {
        descriptionLabel.font = .systemFont(ofSize: 15, weight: .regular)
        descriptionLabel.textColor = .label
        descriptionLabel.numberOfLines = 4
    }

    private func configureExpandButton() {
        expandButton.setTitle("Xem thêm", for: .normal)
        expandButton.setTitleColor(.systemBlue, for: .normal)
        expandButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        expandButton.contentHorizontalAlignment = .left
        expandButton.addTarget(self, action: #selector(didTapExpand), for: .touchUpInside)
        expandButton.isHidden = true
    }

    private func configureButtons() {
        // Top button stack với favorite button
        topButtonStack.axis = .horizontal
        topButtonStack.spacing = 8
        topButtonStack.alignment = .top
        topButtonStack.distribution = .fill

        configureFavoriteButton()
        topButtonStack.addArrangedSubview(favoriteContainer)
        let spacer = UIView()
        spacer.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        topButtonStack.addArrangedSubview(spacer)

        // Main button stack
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.alignment = .fill

        configureDownloadButton()
        configureSaveButton()

        buttonStack.addArrangedSubview(downloadButton)
        buttonStack.addArrangedSubview(saveButton)
    }

    private func configureFavoriteButton() {
        favoriteContainer.translatesAutoresizingMaskIntoConstraints = false
        favoriteContainer.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.1)
        favoriteContainer.layer.masksToBounds = true
        favoriteContainer.setContentHuggingPriority(.required, for: .horizontal)
        favoriteContainer.setContentCompressionResistancePriority(.required, for: .horizontal)

        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
        favoriteButton.tintColor = .secondaryLabel
        favoriteButton.addTarget(self, action: #selector(didTapFavorite), for: .touchUpInside)
        favoriteButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        favoriteButton.setContentHuggingPriority(.required, for: .horizontal)
        favoriteButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        favoriteContainer.addSubview(favoriteButton)

        NSLayoutConstraint.activate([
            favoriteContainer.widthAnchor.constraint(equalToConstant: 42),
            favoriteContainer.heightAnchor.constraint(equalToConstant: 42),
            favoriteButton.centerXAnchor.constraint(equalTo: favoriteContainer.centerXAnchor),
            favoriteButton.centerYAnchor.constraint(equalTo: favoriteContainer.centerYAnchor)
        ])
    }

    @objc private func didTapFavorite() {
        guard let show = currentShow else { return }

        do {
            if isFavorite {
                try libraryService.unfavoriteShow(show.id)
                isFavorite = false
            } else {
                try libraryService.favoriteShow(show)
                isFavorite = true
            }
            updateFavoriteButton()
            NotificationCenter.default.post(name: NSNotification.Name("LibraryUpdated"), object: nil)
        } catch {
            print("⚠️ Lỗi khi cập nhật yêu thích: \(error.localizedDescription)")
        }
    }

    private func updateFavoriteButton() {
        let imageName = isFavorite ? "heart.fill" : "heart"
        let tintColor = isFavorite ? UIColor.systemRed : UIColor.secondaryLabel
        let backgroundColor = isFavorite ? UIColor.systemRed.withAlphaComponent(0.15) : UIColor.secondaryLabel
            .withAlphaComponent(0.1)

        UIView.animate(withDuration: 0.2) {
            self.favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
            self.favoriteButton.tintColor = tintColor
            self.favoriteContainer.backgroundColor = backgroundColor
        }
    }

    @objc private func didTapExpand() {
        isDescriptionExpanded.toggle()
        updateDescriptionExpansion()
        onLayoutChange?()
    }

    private func updateDescriptionExpansion() {
        descriptionLabel.numberOfLines = isDescriptionExpanded ? 0 : 4
        let title = isDescriptionExpanded ? "Thu gọn" : "Xem thêm"
        expandButton.setTitle(title, for: .normal)
    }

    private func configureDownloadButton() {
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.setTitle("Tải về", for: .normal)
        downloadButton.backgroundColor = .systemBlue
        downloadButton.setTitleColor(.white, for: .normal)
        downloadButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        downloadButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)
        downloadButton.layer.cornerRadius = 14
        downloadButton.layer.cornerCurve = .continuous
        downloadButton.layer.shadowColor = UIColor.systemBlue.cgColor
        downloadButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        downloadButton.layer.shadowRadius = 8
        downloadButton.layer.shadowOpacity = 0.3
        downloadButton.layer.masksToBounds = false
        downloadButton.addTarget(self, action: #selector(didTapDownload), for: .touchUpInside)
    }

    private func configureSaveButton() {
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Lưu", for: .normal)
        saveButton.setTitleColor(.systemBlue, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        saveButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        saveButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)
        saveButton.layer.cornerRadius = 14
        saveButton.layer.cornerCurve = .continuous
        saveButton.layer.masksToBounds = true
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
    }

    @objc private func didTapDownload() {
        guard let show = currentShow else { return }

        do {
            let isDownloaded = libraryService.isShowDownloaded(show.id)
            if isDownloaded {
                try libraryService.removeDownloadedShow(show.id)
            } else {
                try libraryService.downloadShow(show)
            }
            updateButtonStates(show: show)
            NotificationCenter.default.post(name: NSNotification.Name("LibraryUpdated"), object: nil)
        } catch {
            print("⚠️ Lỗi khi tải về: \(error.localizedDescription)")
        }
    }

    @objc private func didTapSave() {
        guard let show = currentShow else { return }

        do {
            let isSaved = libraryService.isShowSaved(show.id)
            if isSaved {
                try libraryService.removeSavedShow(show.id)
            } else {
                try libraryService.saveShow(show)
            }
            updateButtonStates(show: show)
            NotificationCenter.default.post(name: NSNotification.Name("LibraryUpdated"), object: nil)
        } catch {
            print("⚠️ Lỗi khi lưu: \(error.localizedDescription)")
        }
    }

    private func makeMetaBadge(icon: String, text: String) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.spacing = 6

        let imageView = UIImageView(image: UIImage(systemName: icon))
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel

        container.addArrangedSubview(imageView)
        container.addArrangedSubview(label)

        return container
    }

    private func makeChipLabel(text: String) -> UIView {
        let label = PaddingLabel(insets: UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .systemBlue
        label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        return label
    }
}

private final class PaddingLabel: UILabel {
    private let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}

extension UIColor {
    fileprivate func darker(by percentage: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        guard getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }

        let newBrightness = max(brightness * (1 - percentage), 0)
        return UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
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
        backgroundColor = .secondarySystemGroupedBackground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .systemGray5

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        detailLabel.font = .systemFont(ofSize: 14, weight: .regular)
        detailLabel.textColor = .secondaryLabel
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        // Custom accessory view
        let accessoryImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        accessoryImageView.tintColor = .tertiaryLabel
        accessoryImageView.contentMode = .scaleAspectFit
        accessoryView = accessoryImageView

        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
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
