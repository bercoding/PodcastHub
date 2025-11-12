import AVFoundation
import MediaPlayer
import UIKit

final class RemoteCommandHandler {
    static let shared = RemoteCommandHandler()

    private let commandCenter = MPRemoteCommandCenter.shared()
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()

    private init() {
        setupRemoteCommands()
    }

    private func setupRemoteCommands() {
        // Play/Pause
        commandCenter.playCommand.addTarget { [weak self] _ in
            let service = PlaybackService.shared
            if !service.isPlaying {
                service.togglePlayPause()
            }
            self?.updateNowPlayingInfo()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            let service = PlaybackService.shared
            if service.isPlaying {
                service.pause()
            }
            self?.updateNowPlayingInfo()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            PlaybackService.shared.togglePlayPause()
            self?.updateNowPlayingInfo()
            return .success
        }

        // Skip Forward/Backward
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            PlaybackService.shared.skipForward(15)
            self?.updateNowPlayingInfo()
            return .success
        }

        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            PlaybackService.shared.skipBackward(15)
            self?.updateNowPlayingInfo()
            return .success
        }

        // Seek
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            PlaybackService.shared.seek(to: event.positionTime)
            self?.updateNowPlayingInfo()
            return .success
        }

        // Enable commands
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
    }

    func updateNowPlayingInfo(
        title: String? = nil,
        artist: String? = nil,
        artwork: UIImage? = nil,
        duration: TimeInterval? = nil,
        currentTime: TimeInterval? = nil,
        playbackRate: Float? = nil
    ) {
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

        if let title {
            nowPlayingInfo[MPMediaItemPropertyTitle] = title
        }

        if let artist {
            nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        }

        if let artwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in
                artwork
            }
        }

        if let duration {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }

        if let currentTime {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        }

        if let playbackRate {
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate
        }

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
}
