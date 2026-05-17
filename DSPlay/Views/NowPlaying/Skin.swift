import SwiftUI

/// Data + actions passed to each NowPlaying skin (mirrors web SkinProps).
struct SkinContext {
    let track: TrackDTO
    let isPlaying: Bool
    let position: Double
    let duration: Double
    let cover: PlatformImage?
    let onPlayPause: () -> Void
    let onSeek: (Double) -> Void
    let onNext: () -> Void
    let onPrev: () -> Void
    let onClose: () -> Void

    var progress: Double { duration > 0 ? position / duration : 0 }
}

protocol NowPlayingSkin: View {
    init(ctx: SkinContext)
}

/// Shared click/drag-to-seek strip used by every skin.
struct SeekBar: View {
    let progress: Double
    let height: CGFloat
    let track: AnyView
    let fill: AnyView
    let onScrub: (Double) -> Void   // 0...1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                track.frame(width: geo.size.width, height: height)
                fill.frame(width: max(0, geo.size.width * progress), height: height)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { v in
                        onScrub(min(1, max(0, v.location.x / geo.size.width)))
                    }
            )
            .onTapGesture { /* tap handled via drag onEnded for location */ }
        }
        .frame(height: max(height, 8))
    }
}
