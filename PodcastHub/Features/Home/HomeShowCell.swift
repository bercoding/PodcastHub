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
        // NOTE: sẽ tích hợp image loader (vd. Kingfisher) ở sprint tiếp theo
        artworkImageView.image = UIImage(systemName: "waveform.circle.fill")
    }

    private func setupViews() {
        accessoryType = .disclosureIndicator
        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        artworkImageView.layer.cornerRadius = 8
        artworkImageView.layer.masksToBounds = true
        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.tintColor = .systemBlue

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        publisherLabel.font = .preferredFont(forTextStyle: .subheadline)
        publisherLabel.textColor = .secondaryLabel
        publisherLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(artworkImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(publisherLabel)

        NSLayoutConstraint.activate([
            artworkImageView.widthAnchor.constraint(equalToConstant: 64),
            artworkImageView.heightAnchor.constraint(equalToConstant: 64),
            artworkImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            artworkImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            artworkImageView.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -12
            ),
            titleLabel.topAnchor.constraint(equalTo: artworkImageView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: artworkImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            publisherLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            publisherLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            publisherLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            publisherLabel.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -12
            )
        ])
    }
}
