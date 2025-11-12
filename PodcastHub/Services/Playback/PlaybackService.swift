import AVFoundation
import Foundation

final class PlaybackService {
    static let shared = PlaybackService()

    private var player: AVPlayer?
    private(set) var currentURL: URL?
    private var timeObserverToken: Any?

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.allowBluetooth, .allowAirPlay])
            try session.setActive(true)
        } catch {
            print("⚠️ Không cấu hình được AVAudioSession: \(error.localizedDescription)")
        }
    }

    func play(url: URL) {
        currentURL = url
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.play()
        NotificationCenter.default.post(name: NSNotification.Name("PlaybackStateChanged"), object: nil)
    }

    func pause() {
        player?.pause()
        NotificationCenter.default.post(name: NSNotification.Name("PlaybackStateChanged"), object: nil)
    }

    func stop() {
        player?.pause()
        player = nil
        currentURL = nil
    }

    var isPlaying: Bool {
        player?.timeControlStatus == .playing
    }

    var duration: TimeInterval {
        guard let duration = player?.currentItem?.duration, duration.isNumeric else { return 0 }
        return CMTimeGetSeconds(duration)
    }

    var currentTime: TimeInterval {
        guard let time = player?.currentTime(), time.isNumeric else { return 0 }
        return CMTimeGetSeconds(time)
    }

    func seek(to seconds: TimeInterval) {
        let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: time)
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            player?.play()
        }
        NotificationCenter.default.post(name: NSNotification.Name("PlaybackStateChanged"), object: nil)
    }

    func addPeriodicTimeObserver(interval: TimeInterval = 0.5, _ callback: @escaping (TimeInterval) -> Void) {
        removePeriodicTimeObserver()
        guard let player else { return }
        let cmInterval = CMTime(seconds: interval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player
            .addPeriodicTimeObserver(forInterval: cmInterval, queue: .main) { [weak self] time in
                guard let self else { return }
                callback(CMTimeGetSeconds(time))
            }
    }

    func removePeriodicTimeObserver() {
        if let token = timeObserverToken, let player {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
}

// MARK: - Advanced controls

extension PlaybackService {
    var rate: Float {
        get { player?.rate ?? 1.0 }
        set {
            guard let player else { return }
            player.rate = isPlaying ? newValue : 0
        }
    }

    func skipForward(_ seconds: TimeInterval = 15) {
        seek(to: currentTime + seconds)
    }

    func skipBackward(_ seconds: TimeInterval = 15) {
        seek(to: max(currentTime - seconds, 0))
    }
}
