import AVFoundation
import Foundation

enum RepeatMode: String {
    case off, all, one
}

@MainActor
final class PlaybackEngine {
    private let player = AVQueuePlayer()
    let state: PlayerState
    private let synology: SynologyClient
    private let nowPlaying = NowPlayingCenter()

    private(set) var queue: [TrackDTO] = []
    private(set) var queueIndex: Int = -1
    private(set) var shuffle: Bool = false
    private(set) var repeatMode: RepeatMode = .off

    var currentTrack: TrackDTO? {
        guard queueIndex >= 0, queueIndex < queue.count else { return nil }
        return queue[queueIndex]
    }

    var isPlaying: Bool { player.rate > 0 }

    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?

    init(state: PlayerState, synology: SynologyClient) {
        self.state = state
        self.synology = synology
        // Honor AirPlay route selection from the system route picker.
        player.allowsExternalPlayback = true

        let interval = CMTime(seconds: 0.25, preferredTimescale: 1000)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let pos = CMTimeGetSeconds(time)
            let dur = self.currentDuration()
            self.state.position = pos
            self.state.duration = dur
            self.nowPlaying.update(track: self.currentTrack, position: pos, duration: dur,
                                   isPlaying: self.player.rate > 0)
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil, queue: .main
        ) { [weak self] _ in
            // Bounce to main actor — the AVFoundation callback queue may not be main.
            Task { @MainActor [weak self] in self?.handleItemDidEnd() }
        }
    }

    deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    }

    // MARK: queue setup

    /// Replace the queue with `tracks`, start playing at `startIndex`.
    func setQueue(tracks: [TrackDTO], startIndex: Int) async throws {
        queue = tracks
        queueIndex = min(max(startIndex, 0), tracks.count - 1)
        syncQueueState()
        try await loadCurrent()
        play()
    }

    /// Append tracks to the existing queue. If nothing is playing, start.
    func queueAdd(tracks: [TrackDTO]) async throws {
        let wasEmpty = queue.isEmpty
        queue.append(contentsOf: tracks)
        syncQueueState()
        if wasEmpty {
            queueIndex = 0
            try await loadCurrent()
            play()
        }
    }

    func queueRemove(at index: Int) async throws {
        guard index >= 0 && index < queue.count else { return }
        let wasCurrent = (index == queueIndex)
        queue.remove(at: index)
        if index < queueIndex {
            queueIndex -= 1
        } else if wasCurrent {
            // The currently playing track was removed — advance.
            if queueIndex >= queue.count { queueIndex = queue.count - 1 }
            if queueIndex >= 0 {
                try await loadCurrent()
                play()
            } else {
                stop()
            }
        }
        syncQueueState()
    }

    func queueClear() {
        queue = []
        queueIndex = -1
        player.removeAllItems()
        state.status = .idle
        nowPlaying.update(track: nil, position: 0, duration: 0, isPlaying: false)
        syncQueueState()
    }

    func queueReorder(from: Int, to: Int) {
        guard from >= 0, from < queue.count, to >= 0, to < queue.count, from != to else { return }
        let moved = queue.remove(at: from)
        queue.insert(moved, at: to)
        // Adjust queueIndex to track the moved item.
        if queueIndex == from {
            queueIndex = to
        } else if from < queueIndex && to >= queueIndex {
            queueIndex -= 1
        } else if from > queueIndex && to <= queueIndex {
            queueIndex += 1
        }
        syncQueueState()
    }

    // MARK: transport

    func play() {
        player.play()
        state.status = .playing
        state.currentTrack = currentTrack
        nowPlaying.update(track: currentTrack, position: CMTimeGetSeconds(player.currentTime()),
                          duration: currentDuration(), isPlaying: true)
    }

    func pause() {
        player.pause()
        state.status = .paused
        state.currentTrack = currentTrack
        nowPlaying.update(track: currentTrack, position: CMTimeGetSeconds(player.currentTime()),
                          duration: currentDuration(), isPlaying: false)
    }

    func toggle() { player.rate == 0 ? play() : pause() }

    func seek(seconds: Double) {
        let cm = CMTime(seconds: seconds, preferredTimescale: 1000)
        player.seek(to: cm)
    }

    func setVolume(_ value: Double) {
        player.volume = Float(max(0, min(1, value)))
    }

    func next() async throws {
        guard !queue.isEmpty else { return }
        let nextIdx = computeNextIndex(after: queueIndex, advanceOnRepeatAll: true)
        guard nextIdx != -1 else { stop(); return }
        queueIndex = nextIdx
        try await loadCurrent()
        play()
        syncQueueState()
    }

    func prev() async throws {
        guard !queue.isEmpty else { return }
        // If we're more than 3 seconds in, restart current track.
        let pos = CMTimeGetSeconds(player.currentTime())
        if pos > 3 {
            seek(seconds: 0)
            return
        }
        let prevIdx = (queueIndex - 1 + queue.count) % queue.count
        queueIndex = prevIdx
        try await loadCurrent()
        play()
        syncQueueState()
    }

    // MARK: modes

    func setShuffle(_ value: Bool) {
        shuffle = value
        syncQueueState()
    }

    func setRepeat(_ mode: RepeatMode) {
        repeatMode = mode
        syncQueueState()
    }

    // MARK: internals

    private func handleItemDidEnd() {
        state.position = 0
        let next = computeNextIndex(after: queueIndex, advanceOnRepeatAll: false)
        if next == -1 {
            state.status = .idle
            nowPlaying.update(track: nil, position: 0, duration: 0, isPlaying: false)
            return
        }
        queueIndex = next
        Task { @MainActor in
            try? await loadCurrent()
            play()
            syncQueueState()
        }
    }

    /// Returns the next queue index. -1 means "stop".
    /// `advanceOnRepeatAll` distinguishes manual "Next" (always advance even in repeat=one)
    /// from auto-advance at song end (repeat=one stays on the same track).
    private func computeNextIndex(after current: Int, advanceOnRepeatAll: Bool) -> Int {
        if repeatMode == .one && !advanceOnRepeatAll {
            return current  // replay the same track
        }
        if shuffle {
            if queue.count <= 1 { return repeatMode == .off ? -1 : current }
            var n = current
            while n == current { n = Int.random(in: 0..<queue.count) }
            return n
        }
        let next = current + 1
        if next < queue.count { return next }
        if repeatMode == .all { return 0 }
        return -1
    }

    func currentDuration() -> Double {
        guard let item = player.currentItem else { return 0 }
        let dur = CMTimeGetSeconds(item.duration)
        return dur.isFinite ? dur : (currentTrack?.duration ?? 0)
    }

    /// Build the AVPlayerItem for the current queue index and replace player items.
    private func loadCurrent() async throws {
        guard let track = currentTrack else { return }
        guard let url = await synology.streamURL(songId: track.id) else {
            throw BridgeHandlerError(kind: "Network", message: "Could not build stream URL for \(track.id)")
        }
        // The stream endpoint transcodes server-side to lossless WAV, so hint
        // AVFoundation accordingly (the URL has no file extension to sniff).
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetOutOfBandMIMETypeKey": "audio/wav"
        ])
        let item = AVPlayerItem(asset: asset)
        player.removeAllItems()
        player.insert(item, after: nil)
        state.status = .loading
        state.currentTrack = track
        nowPlaying.update(track: track, position: 0, duration: track.duration, isPlaying: false)
    }

    private func stop() {
        player.pause()
        player.removeAllItems()
        state.status = .idle
        nowPlaying.update(track: nil, position: 0, duration: 0, isPlaying: false)
    }

    /// Push queue / index / mode state (and the derived current track) into the
    /// observable `PlayerState` the SwiftUI views read.
    private func syncQueueState() {
        state.queue = queue
        state.queueIndex = queueIndex
        state.shuffle = shuffle
        state.repeatMode = repeatMode
        state.currentTrack = currentTrack
    }
}
