import Observation

enum PlaybackStatus: String {
    case idle, loading, playing, paused, error
}

/// Observable mirror of `PlaybackEngine`'s authoritative state. SwiftUI views
/// observe this directly — it replaces the old Swift→JS `BridgeEvents` push
/// channel and the menu-bar mini player's 0.5s polling Timer.
@MainActor
@Observable
final class PlayerState {
    var status: PlaybackStatus = .idle
    var currentTrack: TrackDTO?
    var position: Double = 0
    var duration: Double = 0
    var queue: [TrackDTO] = []
    var queueIndex: Int = -1
    var shuffle: Bool = false
    var repeatMode: RepeatMode = .off

    var isPlaying: Bool { status == .playing }
    var hasQueue: Bool { !queue.isEmpty }
}
