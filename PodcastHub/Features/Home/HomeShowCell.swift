import UIKit

final class HomeShowCell: UITableViewCell {
    static let reuseIdentifier = "HomeShowCell"

    private let artworkImageView = UIImageView()
    private let titleLabel = UILabel()
    private let publisherLabel = UILabel()

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
    }

    func configure(with show: Show) {
        titleLabel.text = show.title
        publisherLabel.text = show.publisher

        // Load artwork
        if let url = show.imageURL {
            loadImage(from: url)
        } else {
            artworkImageView.image = UIImage(systemName: "waveform.circle.fill")
            artworkImageView.tintColor = .systemBlue
            artworkImageView.backgroundColor = .secondarySystemBackground
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
                    duration: 0.2,
                    options: .transitionCrossDissolve
                ) {
                    self.artworkImageView.image = image
                    self.artworkImageView.backgroundColor = .clear
                }
            }
        }
        task.resume()
    }

    private func setupViews() {
        backgroundColor = .secondarySystemGroupedBackground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .systemGray5

        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        artworkImageView.layer.cornerRadius = 10
        artworkImageView.layer.masksToBounds = true
        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.backgroundColor = .secondarySystemBackground
        artworkImageView.tintColor = .systemBlue
        // Thêm shadow nhẹ
        artworkImageView.layer.shadowColor = UIColor.black.cgColor
        artworkImageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        artworkImageView.layer.shadowRadius = 3
        artworkImageView.layer.shadowOpacity = 0.1
        artworkImageView.layer.masksToBounds = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        publisherLabel.font = .systemFont(ofSize: 14, weight: .regular)
        publisherLabel.textColor = .secondaryLabel
        publisherLabel.translatesAutoresizingMaskIntoConstraints = false

        // Custom accessory view
        let accessoryImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        accessoryImageView.tintColor = .tertiaryLabel
        accessoryImageView.contentMode = .scaleAspectFit
        accessoryView = accessoryImageView

        contentView.addSubview(artworkImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(publisherLabel)

        NSLayoutConstraint.activate([
            artworkImageView.widthAnchor.constraint(equalToConstant: 72),
            artworkImageView.heightAnchor.constraint(equalToConstant: 72),
            artworkImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            artworkImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            artworkImageView.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -12
            ),
            titleLabel.topAnchor.constraint(equalTo: artworkImageView.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: artworkImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            publisherLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            publisherLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            publisherLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            publisherLabel.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -12
            )
        ])
    }
}
