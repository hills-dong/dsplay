import MediaPlayer
import Foundation

@MainActor
final class NowPlayingCenter {
    private let center = MPNowPlayingInfoCenter.default()

    func update(track: TrackDTO?, position: Double, duration: Double, isPlaying: Bool) {
        guard let track else {
            center.nowPlayingInfo = nil
            return
        }
        let info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPMediaItemPropertyPlaybackDuration: duration > 0 ? duration : track.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: position,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
        center.playbackState = isPlaying ? .playing : .paused
        center.nowPlayingInfo = info
    }
}
