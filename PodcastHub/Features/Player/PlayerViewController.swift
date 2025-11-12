import AVKit
import UIKit

final class PlayerViewController: UIViewController {
    private let episodeTitle: String
    private let artworkURL: URL?
    private let audioURL: URL

    private let backdropOverlayView = UIView()
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
    private let controlsStack = UIStackView()
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
        configureBackdrop()
        configureArtwork()
        configureLabels()
        configureControlButtons()
        configureSlider()
        configureUpNext()
        addSubviews()
        applyConstraints()
    }

    private func configureBackdrop() {
        backdropOverlayView.translatesAutoresizingMaskIntoConstraints = false
        backdropOverlayView.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.35)
                : UIColor.white.withAlphaComponent(0.28)
        }
        backdropOverlayView.layer.cornerRadius = 24
        backdropOverlayView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        backdropOverlayView.layer.masksToBounds = true
        backdropOverlayView.alpha = 0.0
    }

    private func configureArtwork() {
        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.backgroundColor = .secondarySystemBackground
        artworkImageView.clipsToBounds = true
        artworkImageView.layer.cornerRadius = 16
        // Thêm shadow container để shadow hoạt động với corner radius
        artworkImageView.layer.shadowColor = UIColor.black.cgColor
        artworkImageView.layer.shadowOffset = CGSize(width: 0, height: 8)
        artworkImageView.layer.shadowRadius = 20
        artworkImageView.layer.shadowOpacity = 0.4
        artworkImageView.layer.masksToBounds = false
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.35).cgColor]
        gradientLayer.locations = [0.6, 1.0]
        artworkImageView.layer.addSublayer(gradientLayer)
    }

    private func configureLabels() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.backgroundColor = .clear
        // Thêm shadow để text nổi bật hơn
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLabel.layer.shadowRadius = 3
        titleLabel.layer.shadowOpacity = 0.3
    }

    private func configureControlButtons() {
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
        playPauseButton.tintColor = .systemBlue
        playPauseButton.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)
        playPauseButton.contentHorizontalAlignment = .fill
        playPauseButton.contentVerticalAlignment = .fill
        // Thêm shadow cho play button
        playPauseButton.layer.shadowColor = UIColor.systemBlue.cgColor
        playPauseButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        playPauseButton.layer.shadowRadius = 8
        playPauseButton.layer.shadowOpacity = 0.4

        back15Button.translatesAutoresizingMaskIntoConstraints = false
        back15Button.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        back15Button.tintColor = .label
        back15Button.backgroundColor = UIColor.label.withAlphaComponent(0.1)
        back15Button.layer.cornerRadius = 22
        back15Button.addTarget(self, action: #selector(didTapBack15), for: .touchUpInside)

        forward15Button.translatesAutoresizingMaskIntoConstraints = false
        forward15Button.setImage(UIImage(systemName: "goforward.15"), for: .normal)
        forward15Button.tintColor = .label
        forward15Button.backgroundColor = UIColor.label.withAlphaComponent(0.1)
        forward15Button.layer.cornerRadius = 22
        forward15Button.addTarget(self, action: #selector(didTapForward15), for: .touchUpInside)

        speedButton.translatesAutoresizingMaskIntoConstraints = false
        speedButton.setTitle("1x", for: .normal)
        speedButton.setTitleColor(.label, for: .normal)
        speedButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        speedButton.tintColor = .label
        speedButton.backgroundColor = UIColor.label.withAlphaComponent(0.1)
        speedButton.layer.cornerRadius = 18
        speedButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        speedButton.addTarget(self, action: #selector(didTapSpeed), for: .touchUpInside)

        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
        controlsContainer.layer.cornerRadius = 20
        controlsContainer.clipsToBounds = true
        // Thêm shadow cho container
        controlsContainer.layer.shadowColor = UIColor.black.cgColor
        controlsContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        controlsContainer.layer.shadowRadius = 12
        controlsContainer.layer.shadowOpacity = 0.2
        controlsContainer.layer.masksToBounds = false

        routePicker.translatesAutoresizingMaskIntoConstraints = false
        routePicker.tintColor = .label

        // Close Button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        closeButton.tintColor = .label
        closeButton.backgroundColor = UIColor.label.withAlphaComponent(0.2)
        closeButton.layer.cornerRadius = 20
        // Thêm shadow để nổi bật hơn
        closeButton.layer.shadowColor = UIColor.black.cgColor
        closeButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        closeButton.layer.shadowRadius = 4
        closeButton.layer.shadowOpacity = 0.3
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)

        // Controls stack setup
        controlsStack.axis = .horizontal
        controlsStack.alignment = .center
        controlsStack.distribution = .equalCentering
        controlsStack.spacing = 24
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        controlsStack.addArrangedSubview(routePicker)
        controlsStack.addArrangedSubview(back15Button)
        controlsStack.addArrangedSubview(playPauseButton)
        controlsStack.addArrangedSubview(forward15Button)
        controlsStack.addArrangedSubview(speedButton)
    }

    private func configureSlider() {
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        currentTimeLabel.text = "0:00"
        currentTimeLabel.textColor = .label
        currentTimeLabel.backgroundColor = .clear

        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        durationLabel.textAlignment = .right
        durationLabel.text = "0:00"
        durationLabel.textColor = .label
        durationLabel.backgroundColor = .clear

        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = UIColor.label.withAlphaComponent(0.2)
        slider.thumbTintColor = .white
        // Thêm shadow cho thumb
        slider.addTarget(self, action: #selector(didSlide(_:)), for: .valueChanged)
    }

    private func configureUpNext() {
        upNextLabel.translatesAutoresizingMaskIntoConstraints = false
        upNextLabel.font = .preferredFont(forTextStyle: .subheadline)
        upNextLabel.textColor = .secondaryLabel
        upNextLabel.text = "Up Next – đang cập nhật"
    }

    private func addSubviews() {
        // Backdrop overlay ở dưới cùng
        view.addSubview(backdropOverlayView)

        // Các controls và content ở trên
        view.addSubview(artworkImageView)
        view.addSubview(titleLabel)
        view.addSubview(controlsContainer)
        controlsContainer.contentView.addSubview(controlsStack)
        view.addSubview(currentTimeLabel)
        view.addSubview(durationLabel)
        view.addSubview(slider)
        view.addSubview(upNextLabel)

        // Close button và controls ở trên cùng để luôn hiển thị
        view.addSubview(closeButton)

        // Đảm bảo tất cả controls nằm trên backdrop
        view.bringSubviewToFront(closeButton)
        view.bringSubviewToFront(controlsContainer)
        view.bringSubviewToFront(titleLabel)
        view.bringSubviewToFront(currentTimeLabel)
        view.bringSubviewToFront(durationLabel)
        view.bringSubviewToFront(slider)
        view.bringSubviewToFront(upNextLabel)
    }

    private func applyConstraints() {
        NSLayoutConstraint.activate([
            backdropOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Close Button - đặt trên artwork với khoảng cách hợp lý
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            artworkImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            artworkImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            artworkImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75),
            artworkImageView.heightAnchor.constraint(equalTo: artworkImageView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: artworkImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: artworkImageView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: artworkImageView.trailingAnchor),

            controlsContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            controlsContainer.leadingAnchor.constraint(equalTo: artworkImageView.leadingAnchor),
            controlsContainer.trailingAnchor.constraint(equalTo: artworkImageView.trailingAnchor),
            controlsContainer.heightAnchor.constraint(equalToConstant: 88),

            controlsStack.leadingAnchor.constraint(
                equalTo: controlsContainer.contentView.leadingAnchor,
                constant: 24
            ),
            controlsStack.trailingAnchor.constraint(
                equalTo: controlsContainer.contentView.trailingAnchor,
                constant: -24
            ),
            controlsStack.topAnchor.constraint(
                equalTo: controlsContainer.contentView.topAnchor,
                constant: 12
            ),
            controlsStack.bottomAnchor.constraint(
                equalTo: controlsContainer.contentView.bottomAnchor,
                constant: -12
            ),

            playPauseButton.widthAnchor.constraint(equalToConstant: 72),
            playPauseButton.heightAnchor.constraint(equalTo: playPauseButton.widthAnchor),

            back15Button.widthAnchor.constraint(equalToConstant: 44),
            back15Button.heightAnchor.constraint(equalToConstant: 44),

            forward15Button.widthAnchor.constraint(equalToConstant: 44),
            forward15Button.heightAnchor.constraint(equalToConstant: 44),

            speedButton.heightAnchor.constraint(equalToConstant: 36),

            routePicker.widthAnchor.constraint(equalToConstant: 36),
            routePicker.heightAnchor.constraint(equalToConstant: 36),

            slider.topAnchor.constraint(equalTo: controlsContainer.bottomAnchor, constant: 24),
            slider.leadingAnchor.constraint(equalTo: artworkImageView.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: artworkImageView.trailingAnchor),

            currentTimeLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 12),
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
            let fallback = UIColor.systemBlue
            artworkImageView.image = UIImage(systemName: "waveform.circle.fill")
            artworkImageView.tintColor = fallback
            let adjusted = adjustedBackgroundColor(from: fallback)
            gradientLayer.colors = [
                UIColor.clear.cgColor,
                adjusted.withAlphaComponent(0.7).cgColor
            ]
            view.backgroundColor = adjusted
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
                applyFallbackAppearance()
                return
            }

            guard let data, let image = UIImage(data: data) else {
                applyFallbackAppearance()
                return
            }

            DispatchQueue.main.async {
                UIView.transition(
                    with: self.artworkImageView,
                    duration: 0.25,
                    options: .transitionCrossDissolve
                ) {
                    self.artworkImageView.image = image
                    let averageColor = image.averageColor
                    let background = self.adjustedBackgroundColor(from: averageColor)
                    self.animateBackdrop(into: background)
                    self.gradientLayer.colors = [
                        UIColor.clear.cgColor,
                        background.withAlphaComponent(0.7).cgColor
                    ]
                    self.view.backgroundColor = background
                }
            }
        }
        task.resume()
    }

    private func applyFallbackAppearance() {
        DispatchQueue.main.async {
            let fallback = UIColor.systemBlue
            self.artworkImageView.image = UIImage(systemName: "waveform.circle.fill")
            self.artworkImageView.tintColor = fallback
            let adjusted = self.adjustedBackgroundColor(from: fallback)
            self.animateBackdrop(into: adjusted)
            self.gradientLayer.colors = [
                UIColor.clear.cgColor,
                adjusted.withAlphaComponent(0.7).cgColor
            ]
            self.view.backgroundColor = adjusted
        }
    }

    private func animateBackdrop(into color: UIColor) {
        UIView.animate(withDuration: 0.3) {
            self.backdropOverlayView.alpha = 1
            self.backdropOverlayView.backgroundColor = color.withAlphaComponent(
                self.traitCollection.userInterfaceStyle == .dark ? 0.4 : 0.3
            )
        }
    }

    private func adjustedBackgroundColor(from color: UIColor) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return UIColor { trait in
                trait.userInterfaceStyle == .dark ? .black : .systemGroupedBackground
            }
        }

        let minBrightness: CGFloat = traitCollection.userInterfaceStyle == .dark ? 0.3 : 0.45
        let adjustedBrightness = max(brightness, minBrightness)
        let adjustedSaturation = saturation * 0.65

        return UIColor(
            hue: hue,
            saturation: adjustedSaturation,
            brightness: adjustedBrightness,
            alpha: 1
        ).withAlphaComponent(0.9)
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
