import UIKit

final class MiniPlayerManager {
    static let shared = MiniPlayerManager()

    private var miniPlayerView: MiniPlayerView?
    private var currentEpisodeTitle: String?
    private var currentArtworkURL: URL?
    private var currentAudioURL: URL?
    private weak var tabBarController: UITabBarController?

    private init() {
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackStateChanged),
            name: NSNotification.Name("PlaybackStateChanged"),
            object: nil
        )
    }

    func attach(to tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
        setupMiniPlayer()
    }

    private func setupMiniPlayer() {
        guard let tabBarController else { return }

        let miniPlayer = MiniPlayerView()
        miniPlayer.translatesAutoresizingMaskIntoConstraints = false
        miniPlayer.isHidden = true
        miniPlayer.onPlayPauseTapped = { [weak self] in
            PlaybackService.shared.togglePlayPause()
            self?.updatePlaybackState()
        }
        miniPlayer.onTapped = { [weak self] in
            self?.openFullPlayer()
        }
        miniPlayer.onCloseTapped = { [weak self] in
            self?.stopPlayback()
        }

        tabBarController.view.addSubview(miniPlayer)

        NSLayoutConstraint.activate([
            miniPlayer.leadingAnchor.constraint(equalTo: tabBarController.view.leadingAnchor),
            miniPlayer.trailingAnchor.constraint(equalTo: tabBarController.view.trailingAnchor),
            miniPlayer.bottomAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor),
            miniPlayer.heightAnchor.constraint(equalToConstant: 64)
        ])

        miniPlayerView = miniPlayer
    }

    func show(episodeTitle: String, artworkURL: URL?, audioURL: URL) {
        currentEpisodeTitle = episodeTitle
        currentArtworkURL = artworkURL
        currentAudioURL = audioURL

        miniPlayerView?.update(title: episodeTitle, artworkURL: artworkURL)
        miniPlayerView?.isHidden = false
        updatePlaybackState()
    }

    func hide() {
        miniPlayerView?.isHidden = true
        currentEpisodeTitle = nil
        currentArtworkURL = nil
        currentAudioURL = nil
    }

    func updatePlaybackState() {
        let isPlaying = PlaybackService.shared.isPlaying
        miniPlayerView?.updatePlaybackState(isPlaying: isPlaying)
    }

    private func openFullPlayer() {
        guard
            let title = currentEpisodeTitle,
            let audioURL = currentAudioURL else { return }

        // Tìm topmost view controller để present
        guard let topVC = topMostViewController() else { return }

        // Kiểm tra xem đã có PlayerViewController đang present chưa
        if topVC is PlayerViewController {
            return // Đã có PlayerViewController rồi, không cần present lại
        }

        let playerVC = PlayerViewController(
            episodeTitle: title,
            artworkURL: currentArtworkURL,
            audioURL: audioURL
        )
        playerVC.modalPresentationStyle = .fullScreen

        topVC.present(playerVC, animated: true)
    }

    private func topMostViewController() -> UIViewController? {
        guard let tabBarController else { return nil }

        var topVC: UIViewController? = tabBarController

        // Tìm topmost presented view controller
        while let presented = topVC?.presentedViewController {
            topVC = presented
        }

        // Nếu topVC là navigation controller, lấy topViewController
        if let navController = topVC as? UINavigationController {
            return navController.topViewController ?? navController
        }

        return topVC
    }

    private func stopPlayback() {
        PlaybackService.shared.stop()
        hide()
    }

    @objc private func playbackStateChanged() {
        updatePlaybackState()
    }
}
