import MediaPlayer

@MainActor
final class RemoteCommands {
    private weak var engine: PlaybackEngine?
    private let events: BridgeEvents

    init(engine: PlaybackEngine, events: BridgeEvents) {
        self.engine = engine
        self.events = events
        install()
    }

    private func install() {
        let cc = MPRemoteCommandCenter.shared()

        cc.playCommand.isEnabled = true
        cc.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.engine?.play(); self?.events.mediaKey("toggle") }
            return .success
        }
        cc.pauseCommand.isEnabled = true
        cc.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.engine?.pause(); self?.events.mediaKey("toggle") }
            return .success
        }
        cc.togglePlayPauseCommand.isEnabled = true
        cc.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.engine?.toggle(); self?.events.mediaKey("toggle") }
            return .success
        }
        cc.nextTrackCommand.isEnabled = true
        cc.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.events.mediaKey("next")
                try? await self?.engine?.next()
            }
            return .success
        }
        cc.previousTrackCommand.isEnabled = true
        cc.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.events.mediaKey("prev")
                try? await self?.engine?.prev()
            }
            return .success
        }

        cc.changePlaybackPositionCommand.isEnabled = true
        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor [weak self] in self?.engine?.seek(seconds: e.positionTime) }
            return .success
        }
    }
}
