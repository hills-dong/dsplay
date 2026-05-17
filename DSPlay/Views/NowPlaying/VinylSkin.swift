import SwiftUI

struct VinylSkin: NowPlayingSkin {
    let ctx: SkinContext
    init(ctx: SkinContext) { self.ctx = ctx }

    private let gold = Color(red: 0xd4/255, green: 0xaf/255, blue: 0x6a/255)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RadialGradient(
                colors: [Color(red: 0x3a/255, green: 0x24/255, blue: 0x18/255),
                         Color(red: 0x1a/255, green: 0x0f/255, blue: 0x08/255),
                         Color(red: 0x0a/255, green: 0x06/255, blue: 0x04/255)],
                center: UnitPoint(x: 0.2, y: 0.3), startRadius: 0, endRadius: 900)

            HStack(spacing: 64) {
                disc
                VStack(alignment: .leading, spacing: 0) {
                    Text("A SIDE · TRACK")
                        .font(.system(size: 11)).tracking(3).opacity(0.6)
                    Text(ctx.track.title)
                        .font(.custom("Georgia", size: 42)).italic()
                        .padding(.vertical, 10)
                    Text(ctx.track.artist.uppercased())
                        .font(.system(size: 15)).tracking(2).opacity(0.85)

                    VStack(spacing: 10) {
                        SeekBar(
                            progress: ctx.progress, height: 1,
                            track: AnyView(gold.opacity(0.3)),
                            fill: AnyView(gold.opacity(0.6)),
                            onScrub: { ctx.onSeek($0 * ctx.duration) }
                        )
                        HStack {
                            Text(fmtTime(ctx.position))
                            Spacer()
                            Text(fmtTime(ctx.duration))
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .tracking(1).opacity(0.7)
                    }
                    .padding(.top, 36)

                    HStack(spacing: 24) {
                        vinylButton("⏮ prev", filled: false, action: ctx.onPrev)
                        vinylButton(ctx.isPlaying ? "pause" : "play",
                                    filled: true, minWidth: 120, action: ctx.onPlayPause)
                        vinylButton("next ⏭", filled: false, action: ctx.onNext)
                    }
                    .padding(.top, 36)
                }
                .frame(maxWidth: 520, alignment: .leading)
            }
            .foregroundStyle(gold)
            .padding(64)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            SkinSwitcherView(tint: gold, closeLabel: "ESC")
                .padding(.top, 32).padding(.trailing, 32)
        }
    }

    private var disc: some View {
        TimelineView(.animation(paused: !ctx.isPlaying)) { timeline in
            // 60°/sec = 1 rev / 6s, matching the web skin.
            let angle = ctx.isPlaying
                ? (timeline.date.timeIntervalSinceReferenceDate * 60)
                    .truncatingRemainder(dividingBy: 360)
                : 0
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(white: 0.1), .black],
                        center: .center, startRadius: 10, endRadius: 190))
                ForEach(0..<24, id: \.self) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.03), lineWidth: 1)
                        .padding(CGFloat(i) * 7)
                }
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(red: 0xcc/255, green: 0x44/255, blue: 0x44/255),
                                 Color(red: 0x88/255, green: 0, blue: 0)],
                        center: .center, startRadius: 0, endRadius: 65))
                    .frame(width: 130, height: 130)
                    .overlay(Circle().stroke(gold, lineWidth: 2))
                    .overlay(
                        Text(ctx.track.album.isEmpty ? "Side A" : ctx.track.album)
                            .font(.custom("Georgia", size: 14)).italic()
                            .foregroundStyle(Color(red: 0x1a/255, green: 0x0a/255, blue: 0x05/255))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(14)
                            .frame(width: 130, height: 130)
                    )
                Circle().fill(gold).frame(width: 8, height: 8)
            }
            .frame(width: 380, height: 380)
            .rotationEffect(.degrees(angle))
            .shadow(color: .black.opacity(0.8), radius: 20, y: 12)
        }
    }

    private func vinylButton(_ label: String, filled: Bool, minWidth: CGFloat = 0,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.custom("Georgia", size: filled ? 14 : 13)).italic()
                .tracking(filled ? 3 : 2)
                .foregroundStyle(filled ? Color(red: 0x1a/255, green: 0x0f/255, blue: 0x08/255) : gold)
                .padding(.horizontal, filled ? 28 : 16)
                .padding(.vertical, filled ? 14 : 10)
                .frame(minWidth: minWidth)
                .background(filled ? gold : Color.clear)
                .overlay(Rectangle().stroke(gold.opacity(filled ? 1 : 0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
