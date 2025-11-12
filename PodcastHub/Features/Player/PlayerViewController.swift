import AVKit
import UIKit

final class PlayerViewController: UIViewController {
    private let episodeTitle: String
    private let artworkURL: URL?
    private let audioURL: URL

    private let artworkImageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let playPauseButton = UIButton(type: .system)
    private let back15Button = UIButton(type: .system)
    private let forward15Button = UIButton(type: .system)
    private let speedButton = UIButton(type: .system)
    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private let slider = UISlider()
    private let upNextLabel = UILabel()
    private let controlsContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let routePicker = AVRoutePickerView()
    private let closeButton = UIButton(type: .system)

    private let feedback = UIImpactFeedbackGenerator(style: .soft)

    init(episodeTitle: String, artworkURL: URL?, audioURL: URL) {
        self.episodeTitle = episodeTitle
        self.artworkURL = artworkURL
        self.audioURL = audioURL
        super.init(nibName: nil, bundle: nil)
        title = "Đang phát"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set background color mặc định sáng hơn
        view.backgroundColor = .systemGroupedBackground
        setupViews()
        configure(with: episodeTitle, artworkURL: artworkURL)

        // Chỉ play nếu chưa có player hoặc URL khác
        if
            let currentURL = PlaybackService.shared.currentURL,
            currentURL.absoluteString == audioURL.absoluteString
        {
            // Đã có player cho URL này, không cần play lại
        } else {
            PlaybackService.shared.play(url: audioURL)
        }

        bindPlayer()
        // Initialize Remote Command Handler
        _ = RemoteCommandHandler.shared
        // Show Mini Player
        MiniPlayerManager.shared.show(
            episodeTitle: episodeTitle,
            artworkURL: artworkURL,
            audioURL: audioURL
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        PlaybackService.shared.removePeriodicTimeObserver()
        // Mini Player sẽ vẫn hiển thị khi dismiss PlayerViewController
    }

    private func setupViews() {
        configureArtwork()
        configureLabels()
        configureControlButtons()
        configureSlider()
        configureUpNext()
        addSubviews()
        applyConstraints()
    }

    private func configureArtwork() {
        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        artworkImageView.layer.cornerRadius = 12
        artworkImageView.layer.masksToBounds = true
        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.backgroundColor = .secondarySystemBackground
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.35).cgColor]
        gradientLayer.locations = [0.6, 1.0]
        artworkImageView.layer.addSublayer(gradientLayer)
    }

    private func configureLabels() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        // Đảm bảo label có background trong suốt để hiển thị
        titleLabel.backgroundColor = .clear
    }

    private func configureControlButtons() {
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
        playPauseButton.tintColor = .systemBlue
        playPauseButton.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)
        playPauseButton.contentHorizontalAlignment = .fill
        playPauseButton.contentVerticalAlignment = .fill

        back15Button.translatesAutoresizingMaskIntoConstraints = false
        back15Button.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        back15Button.addTarget(self, action: #selector(didTapBack15), for: .touchUpInside)

        forward15Button.translatesAutoresizingMaskIntoConstraints = false
        forward15Button.setImage(UIImage(systemName: "goforward.15"), for: .normal)
        forward15Button.addTarget(self, action: #selector(didTapForward15), for: .touchUpInside)

        speedButton.translatesAutoresizingMaskIntoConstraints = false
        speedButton.setTitle("1x", for: .normal)
        speedButton.addTarget(self, action: #selector(didTapSpeed), for: .touchUpInside)

        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
        controlsContainer.layer.cornerRadius = 16
        controlsContainer.clipsToBounds = true
        routePicker.translatesAutoresizingMaskIntoConstraints = false
        routePicker.tintColor = .label

        // Close Button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        closeButton.tintColor = .label
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
    }

    private func configureSlider() {
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        currentTimeLabel.text = "0:00"
        currentTimeLabel.textColor = .label
        currentTimeLabel.backgroundColor = .clear

        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        durationLabel.textAlignment = .right
        durationLabel.text = "0:00"
        durationLabel.textColor = .label
        durationLabel.backgroundColor = .clear

        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(self, action: #selector(didSlide(_:)), for: .valueChanged)
    }

    private func configureUpNext() {
        upNextLabel.translatesAutoresizingMaskIntoConstraints = false
        upNextLabel.font = .preferredFont(forTextStyle: .subheadline)
        upNextLabel.textColor = .secondaryLabel
        upNextLabel.text = "Up Next – đang cập nhật"
    }

    private func addSubviews() {
        view.addSubview(closeButton)
        view.addSubview(artworkImageView)
        view.addSubview(titleLabel)
        view.addSubview(controlsContainer)
        controlsContainer.contentView.addSubview(playPauseButton)
        controlsContainer.contentView.addSubview(back15Button)
        controlsContainer.contentView.addSubview(forward15Button)
        controlsContainer.contentView.addSubview(speedButton)
        controlsContainer.contentView.addSubview(routePicker)
        view.addSubview(currentTimeLabel)
        view.addSubview(durationLabel)
        view.addSubview(slider)
        view.addSubview(upNextLabel)
    }

    private func applyConstraints() {
        NSLayoutConstraint.activate([
            // Close Button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            artworkImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            artworkImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            artworkImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.82),
            artworkImageView.heightAnchor.constraint(equalTo: artworkImageView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: artworkImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: artworkImageView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: artworkImageView.trailingAnchor),

            controlsContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            controlsContainer.leadingAnchor.constraint(equalTo: artworkImageView.leadingAnchor),
            controlsContainer.trailingAnchor.constraint(equalTo: artworkImageView.trailingAnchor),
            controlsContainer.heightAnchor.constraint(equalToConstant: 88),

            playPauseButton.centerXAnchor.constraint(equalTo: controlsContainer.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 64),
            playPauseButton.heightAnchor.constraint(equalTo: playPauseButton.widthAnchor),

            back15Button.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            back15Button.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -28),

            forward15Button.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            forward15Button.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 28),

            speedButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            speedButton.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -12),

            routePicker.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            routePicker.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 12),
            routePicker.widthAnchor.constraint(equalToConstant: 32),
            routePicker.heightAnchor.constraint(equalToConstant: 32),

            slider.topAnchor.constraint(equalTo: controlsContainer.bottomAnchor, constant: 16),
            slider.leadingAnchor.constraint(equalTo: artworkImageView.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: artworkImageView.trailingAnchor),

            currentTimeLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 8),
            currentTimeLabel.leadingAnchor.constraint(equalTo: slider.leadingAnchor),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 60),

            durationLabel.centerYAnchor.constraint(equalTo: currentTimeLabel.centerYAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: slider.trailingAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 60),

            upNextLabel.topAnchor.constraint(equalTo: currentTimeLabel.bottomAnchor, constant: 24),
            upNextLabel.leadingAnchor.constraint(equalTo: slider.leadingAnchor),
            upNextLabel.trailingAnchor.constraint(equalTo: slider.trailingAnchor)
        ])
    }

    private func viewLayoutUpdated() {
        gradientLayer.frame = CGRect(
            x: 0,
            y: artworkImageView.bounds.height * 0.55,
            width: artworkImageView.bounds.width,
            height: artworkImageView.bounds.height * 0.45
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewLayoutUpdated()
    }

    private func configure(with title: String, artworkURL: URL?) {
        titleLabel.text = title
        if let url = artworkURL {
            loadImage(url: url)
        } else {
            artworkImageView.image = UIImage(systemName: "waveform.circle.fill")
            artworkImageView.tintColor = .systemBlue
            view.backgroundColor = .systemGroupedBackground
        }
    }

    private func loadImage(url: URL) {
        // Set placeholder trước khi load
        artworkImageView.image = UIImage(systemName: "waveform.circle.fill")
        artworkImageView.tintColor = .systemBlue
        artworkImageView.backgroundColor = .secondarySystemBackground

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }

            if let error {
                print("⚠️ Lỗi load image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.artworkImageView.image = UIImage(systemName: "waveform.circle.fill")
                    self.artworkImageView.tintColor = .systemBlue
                    self.view.backgroundColor = .systemGroupedBackground
                }
                return
            }

            guard let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.artworkImageView.image = UIImage(systemName: "waveform.circle.fill")
                    self.artworkImageView.tintColor = .systemBlue
                    self.view.backgroundColor = .systemGroupedBackground
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
                    let color = image.averageColor
                    self.gradientLayer.colors = [
                        UIColor.clear.cgColor,
                        color.withAlphaComponent(0.55).cgColor
                    ]
                    // Đảm bảo background không quá tối
                    let bgColor = color.withAlphaComponent(0.12)
                    self.view.backgroundColor = bgColor
                }
            }
        }
        task.resume()
    }

    private func bindPlayer() {
        updateTimeLabels()
        PlaybackService.shared.addPeriodicTimeObserver { [weak self] _ in
            self?.syncUIWithPlayer()
        }
    }

    private func syncUIWithPlayer() {
        let duration = PlaybackService.shared.duration
        let current = PlaybackService.shared.currentTime
        slider.maximumValue = Float(duration)
        slider.value = Float(current)
        updateTimeLabels()
        let playing = PlaybackService.shared.isPlaying
        playPauseButton.setImage(
            UIImage(systemName: playing ? "pause.circle.fill" : "play.circle.fill"),
            for: .normal
        )
        speedButton.setTitle(
            "\(String(format: "%.2gx", PlaybackService.shared.rate))".replacingOccurrences(
                of: ".00",
                with: ""
            ),
            for: .normal
        )

        // Update Now Playing Info for lock screen
        RemoteCommandHandler.shared.updateNowPlayingInfo(
            title: episodeTitle,
            artwork: artworkImageView.image,
            duration: duration > 0 ? duration : nil,
            currentTime: current > 0 ? current : nil,
            playbackRate: playing ? PlaybackService.shared.rate : 0
        )
    }

    private func updateTimeLabels() {
        currentTimeLabel.text = format(PlaybackService.shared.currentTime)
        durationLabel.text = format(PlaybackService.shared.duration)
    }

    private func format(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    @objc private func didTapPlayPause() {
        feedback.impactOccurred()
        PlaybackService.shared.togglePlayPause()
        syncUIWithPlayer()
    }

    @objc private func didTapBack15() {
        feedback.impactOccurred()
        PlaybackService.shared.skipBackward(15)
        syncUIWithPlayer()
    }

    @objc private func didTapForward15() {
        feedback.impactOccurred()
        PlaybackService.shared.skipForward(15)
        syncUIWithPlayer()
    }

    @objc private func didTapSpeed() {
        let rates: [Float] = [1.0, 1.25, 1.5, 2.0]
        let actions = rates.map { rate in
            UIAction(title: "\(rate)x", state: PlaybackService.shared.rate == rate ? .on : .off) { _ in
                PlaybackService.shared.rate = rate
                self.syncUIWithPlayer()
            }
        }
        let menu = UIMenu(title: "Tốc độ phát", children: actions)
        speedButton.showsMenuAsPrimaryAction = true
        speedButton.menu = menu
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    @objc private func didSlide(_ slider: UISlider) {
        PlaybackService.shared.seek(to: TimeInterval(slider.value))
    }
}
