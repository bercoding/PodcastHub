import UIKit

final class HomeShowCell: UITableViewCell {
    static let reuseIdentifier = "HomeShowCell"

    private let containerView = UIView()
    private let artworkImageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let publisherLabel = UILabel()
    private let episodeCountLabel = UILabel()
    private let stackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        artworkImageView.image = nil
        titleLabel.text = nil
        publisherLabel.text = nil
        episodeCountLabel.text = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = artworkImageView.bounds
    }

    func configure(with show: Show) {
        titleLabel.text = show.title
        publisherLabel.text = show.publisher

        // Episode count
        if show.totalEpisodes > 0 {
            episodeCountLabel.text = "\(show.totalEpisodes) tập"
            episodeCountLabel.isHidden = false
        } else {
            episodeCountLabel.isHidden = true
        }

        // Load artwork
        if let url = show.imageURL {
            loadImage(from: url)
        } else {
            artworkImageView.image = UIImage(systemName: "waveform.circle.fill")
            artworkImageView.tintColor = .systemBlue
            artworkImageView.backgroundColor = .secondarySystemBackground
            gradientLayer.isHidden = true
        }
    }

    private func loadImage(from url: URL) {
        artworkImageView.image = UIImage(systemName: "waveform.circle.fill")
        artworkImageView.tintColor = .systemBlue
        artworkImageView.backgroundColor = .secondarySystemBackground

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }

            if let error {
                print("⚠️ Lỗi load artwork: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.artworkImageView.image = UIImage(systemName: "waveform.circle.fill")
                    self.artworkImageView.tintColor = .systemBlue
                }
                return
            }

            guard let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.artworkImageView.image = UIImage(systemName: "waveform.circle.fill")
                    self.artworkImageView.tintColor = .systemBlue
                }
                return
            }

            DispatchQueue.main.async {
                UIView.transition(
                    with: self.artworkImageView,
                    duration: 0.25,
                    options: .transitionCrossDissolve
                ) {
                    self.artworkImageView.image = image
                    self.artworkImageView.backgroundColor = .clear
                    self.gradientLayer.isHidden = false
                }
            }
        }
        task.resume()
    }

    private func setupViews() {
        backgroundColor = .clear
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .clear

        // Container view với shadow và rounded corners
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .secondarySystemGroupedBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.cornerCurve = .continuous
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.masksToBounds = false

        // Artwork với gradient overlay
        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        artworkImageView.layer.cornerRadius = 14
        artworkImageView.layer.cornerCurve = .continuous
        artworkImageView.layer.masksToBounds = true
        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.backgroundColor = .secondarySystemBackground
        artworkImageView.tintColor = .systemBlue

        // Gradient overlay cho artwork
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor
        ]
        gradientLayer.locations = [0.6, 1.0]
        gradientLayer.cornerRadius = 14
        artworkImageView.layer.addSublayer(gradientLayer)
        gradientLayer.isHidden = true

        // Title label
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Publisher label
        publisherLabel.font = .systemFont(ofSize: 15, weight: .medium)
        publisherLabel.textColor = .secondaryLabel
        publisherLabel.numberOfLines = 1
        publisherLabel.translatesAutoresizingMaskIntoConstraints = false

        // Episode count label
        episodeCountLabel.font = .systemFont(ofSize: 13, weight: .regular)
        episodeCountLabel.textColor = .tertiaryLabel
        episodeCountLabel.translatesAutoresizingMaskIntoConstraints = false

        // Stack view cho text content
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(publisherLabel)
        stackView.addArrangedSubview(episodeCountLabel)

        // Custom accessory view
        let accessoryImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        accessoryImageView.tintColor = .tertiaryLabel
        accessoryImageView.contentMode = .scaleAspectFit
        accessoryView = accessoryImageView

        contentView.addSubview(containerView)
        containerView.addSubview(artworkImageView)
        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Artwork - lớn hơn và đẹp hơn
            artworkImageView.widthAnchor.constraint(equalToConstant: 100),
            artworkImageView.heightAnchor.constraint(equalToConstant: 100),
            artworkImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            artworkImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            artworkImageView.bottomAnchor.constraint(
                lessThanOrEqualTo: containerView.bottomAnchor,
                constant: -12
            ),

            // Stack view
            stackView.topAnchor.constraint(equalTo: artworkImageView.topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: artworkImageView.trailingAnchor, constant: 14),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            stackView.bottomAnchor.constraint(
                lessThanOrEqualTo: containerView.bottomAnchor,
                constant: -12
            )
        ])
    }
}
