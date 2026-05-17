import SwiftUI

struct WinampSkin: NowPlayingSkin {
    let ctx: SkinContext
    init(ctx: SkinContext) { self.ctx = ctx }

    private let panelTop = Color(red: 0x5a/255, green: 0x6b/255, blue: 0x78/255)
    private let panelBot = Color(red: 0x2a/255, green: 0x35/255, blue: 0x40/255)
    private let lcdGreen = Color(red: 0, green: 1, blue: 0x66/255)
    private let textCol = Color(red: 0xc0/255, green: 0xc8/255, blue: 0xd0/255)

    private var vu: [Bool] {
        let t = Int(ctx.position * 4)
        return (0..<12).map { i in
            ctx.isPlaying ? ((i * 7 + t * 3) % 13) > i / 2 : false
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(colors: [panelTop, Color(red: 0x11/255, green: 0x18/255, blue: 0x1f/255)],
                           startPoint: .top, endPoint: .bottom)

            VStack(spacing: 0) {
                HStack {
                    Text("■ DSPlay 1.0").foregroundStyle(.white)
                    Spacer()
                    Text("_ □ ×").foregroundStyle(.white).opacity(0.6)
                }
                .font(.system(size: 11))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(LinearGradient(
                    colors: [Color(red: 0x4a/255, green: 0x5b/255, blue: 0x68/255),
                             Color(red: 0x1a/255, green: 0x20/255, blue: 0x28/255)],
                    startPoint: .top, endPoint: .bottom))

                // LCD
                VStack(alignment: .leading, spacing: 4) {
                    Text(fmtTime(ctx.position))
                        .font(.system(size: 28, design: .monospaced))
                        .tracking(3)
                    Text("► \(ctx.track.title) — \(ctx.track.artist)".uppercased())
                        .font(.system(size: 10, design: .monospaced))
                        .opacity(0.85).lineLimit(1)
                    HStack(spacing: 2) {
                        ForEach(0..<12, id: \.self) { i in
                            LinearGradient(
                                colors: [Color(red: 1, green: 0.2, blue: 0),
                                         Color(red: 1, green: 0.8, blue: 0),
                                         lcdGreen],
                                startPoint: .top, endPoint: .bottom)
                                .frame(height: 14)
                                .opacity(vu[i] ? 1 : 0.25)
                        }
                    }
                    .padding(.top, 10)
                }
                .foregroundStyle(lcdGreen)
                .shadow(color: lcdGreen, radius: 3)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0x0a/255, green: 0x0a/255, blue: 0x0a/255))
                .overlay(Rectangle().stroke(panelBot, lineWidth: 1))
                .padding(.top, 12)

                HStack(spacing: 4) {
                    winButton("◄◄", ctx.onPrev)
                    winButton(ctx.isPlaying ? "❚❚" : "►", ctx.onPlayPause)
                    winButton("■", { ctx.onSeek(0) })
                    winButton("►►", ctx.onNext)
                }
                .padding(.top, 12)

                SeekBar(
                    progress: ctx.progress, height: 10,
                    track: AnyView(Color(red: 0x1a/255, green: 0x20/255, blue: 0x28/255)),
                    fill: AnyView(LinearGradient(
                        colors: [Color(red: 0x5a/255, green: 0x8a/255, blue: 0xa8/255),
                                 Color(red: 0x2a/255, green: 0x4a/255, blue: 0x68/255)],
                        startPoint: .top, endPoint: .bottom)),
                    onScrub: { ctx.onSeek($0 * ctx.duration) }
                )
                .overlay(Rectangle().stroke(Color(red: 0x0a/255, green: 0x10/255, blue: 0x18/255), lineWidth: 1))
                .padding(.top, 14)

                HStack {
                    Text(fmtTime(ctx.position))
                    Spacer()
                    Text(fmtTime(ctx.duration))
                }
                .font(.system(size: 10)).foregroundStyle(textCol).opacity(0.7)
                .padding(.top, 6)
            }
            .padding(14)
            .frame(width: 520)
            .background(LinearGradient(colors: [panelTop, panelBot],
                                       startPoint: .top, endPoint: .bottom))
            .overlay(Rectangle().stroke(Color(red: 0x0a/255, green: 0x10/255, blue: 0x18/255), lineWidth: 1))
            .shadow(color: .black.opacity(0.6), radius: 20, y: 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            SkinSwitcherView(tint: textCol, closeLabel: "ESC")
                .padding(.top, 32).padding(.trailing, 32)
        }
    }

    private func winButton(_ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14)).foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(LinearGradient(colors: [panelTop, panelBot],
                                           startPoint: .top, endPoint: .bottom))
                .overlay(Rectangle().stroke(Color(red: 0x0a/255, green: 0x10/255, blue: 0x18/255), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
