import UIKit

final class MiniPlayerView: UIView {
    private let artworkImageView = UIImageView()
    private let titleLabel = UILabel()
    private let playPauseButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    var onPlayPauseTapped: (() -> Void)?
    var onTapped: (() -> Void)?
    var onCloseTapped: (() -> Void)?

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
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1

        // Artwork
        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.clipsToBounds = true
        artworkImageView.layer.cornerRadius = 4
        artworkImageView.backgroundColor = .systemGray5
        addSubview(artworkImageView)

        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.text = "Chưa có bài hát nào"
        addSubview(titleLabel)

        // Play/Pause Button
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.tintColor = .label
        playPauseButton.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)
        addSubview(playPauseButton)

        // Close Button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        addSubview(closeButton)

        // Tap gesture để mở Player đầy đủ
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tapGesture)

        NSLayoutConstraint.activate([
            // Artwork
            artworkImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            artworkImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            artworkImageView.widthAnchor.constraint(equalToConstant: 48),
            artworkImageView.heightAnchor.constraint(equalToConstant: 48),

            // Title
            titleLabel.leadingAnchor.constraint(equalTo: artworkImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: playPauseButton.leadingAnchor,
                constant: -12
            ),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Play/Pause Button
            playPauseButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            playPauseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 44),
            playPauseButton.heightAnchor.constraint(equalToConstant: 44),

            // Close Button
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func update(title: String, artworkURL: URL?) {
        titleLabel.text = title

        if let url = artworkURL {
            Task {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    await MainActor.run {
                        self.artworkImageView.image = image
                    }
                }
            }
        } else {
            artworkImageView.image = UIImage(systemName: "waveform.circle.fill")
            artworkImageView.tintColor = .systemBlue
        }
    }

    func updatePlaybackState(isPlaying: Bool) {
        playPauseButton.setImage(
            UIImage(systemName: isPlaying ? "pause.fill" : "play.fill"),
            for: .normal
        )
    }

    @objc private func didTap() {
        onTapped?()
    }

    @objc private func didTapPlayPause() {
        onPlayPauseTapped?()
    }

    @objc private func didTapClose() {
        onCloseTapped?()
    }
}
