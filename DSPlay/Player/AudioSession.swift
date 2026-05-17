import Foundation
#if os(iOS)
import AVFoundation
#endif

/// Cross-platform audio-session bootstrap. On iOS the `.playback` category
/// plus `UIBackgroundModes: [audio]` (Info.plist) is what enables background
/// audio and the lock-screen / control-center transport that
/// `RemoteCommands` / `NowPlayingCenter` drive. On macOS there is no
/// AVAudioSession — AVQueuePlayer plays directly — so this is a no-op.
enum AudioSession {
    static func activatePlayback() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
        #endif
    }
}
