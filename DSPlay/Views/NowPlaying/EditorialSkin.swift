import SwiftUI

struct EditorialSkin: NowPlayingSkin {
    let ctx: SkinContext
    init(ctx: SkinContext) { self.ctx = ctx }

    #if os(iOS)
    private let coverMax: CGFloat = 340
    private let outerPad: CGFloat = 20
    private let titleSize: CGFloat = 26
    #else
    private let coverMax: CGFloat = 340
    private let outerPad: CGFloat = 40
    private let titleSize: CGFloat = 30
    #endif

    var body: some View {
        ZStack {
            // Blurred cover backdrop. Clipped + clamped so the scaledToFill
            // image can never dictate the ZStack's size (which would push the
            // foreground off-centre on a narrow screen).
            Color.black
                .overlay {
                    Group {
                        if let c = ctx.cover {
                            Image(platformImage: c).resizable().scaledToFill()
                        } else {
                            LinearGradient(colors: [.gray.opacity(0.4), .black.opacity(0.6)],
                                           startPoint: .top, endPoint: .bottom)
                        }
                    }
                    .blur(radius: 60)
                    .overlay(.black.opacity(0.28))
                    .overlay(.ultraThinMaterial.opacity(0.4))
                }
                .clipped()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 0)

                // Cover art — square, capped, shrinks on narrow screens.
                ZStack {
                    if let c = ctx.cover {
                        Image(platformImage: c).resizable().scaledToFill()
                    } else {
                        Theme.coverBG
                        Image(systemName: "music.note").font(.system(size: 64))
                            .foregroundStyle(.secondary)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: coverMax)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.45), radius: 30, y: 18)

                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Text(ctx.track.title)
                            .font(.system(size: titleSize, weight: .bold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                        QualityBadge(track: ctx.track)
                    }
                    Text(ctx.track.artist)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(ctx.track.album)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                // Scrubber
                VStack(spacing: 6) {
                    SeekBar(
                        progress: ctx.progress, height: 5,
                        track: AnyView(Capsule().fill(.quaternary)),
                        fill: AnyView(Capsule().fill(Theme.accent)),
                        onScrub: { ctx.onSeek($0 * ctx.duration) }
                    )
                    HStack {
                        Text(fmtTime(ctx.position))
                        Spacer()
                        Text(fmtTime(ctx.duration))
                    }
                    .font(Theme.mono(11))
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: 420)

                // Transport — same plain SF-symbol style as the bottom bar.
                HStack(spacing: 30) {
                    plainButton("backward.fill", 24, action: ctx.onPrev)
                    plainButton(ctx.isPlaying ? "pause.fill" : "play.fill", 34,
                                action: ctx.onPlayPause)
                    plainButton("forward.fill", 24, action: ctx.onNext)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(outerPad)
        }
        .overlay(alignment: .topTrailing) {
            SkinSwitcherView()
                #if os(iOS)
                .padding(.top, 54).padding(.trailing, 16)
                #else
                .padding(.top, 20).padding(.trailing, 20)
                #endif
        }
    }

    private func plainButton(_ symbol: String, _ size: CGFloat,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size))
                .foregroundStyle(.primary)
                .frame(width: size + 16, height: size + 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
