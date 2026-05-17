import SwiftUI

struct TerminalSkin: NowPlayingSkin {
    let ctx: SkinContext
    init(ctx: SkinContext) { self.ctx = ctx }

    private let green = Color(red: 0x33/255, green: 1, blue: 0x66/255)
    private let bg = Color(red: 0x05/255, green: 0x08/255, blue: 0x05/255)

    private func bar(_ p: Double, width: Int = 38) -> String {
        let filled = max(0, min(width, Int((p * Double(width)).rounded())))
        return String(repeating: "#", count: filled) + String(repeating: "-", count: width - filled)
    }
    private func ts(_ s: Double) -> String {
        guard s.isFinite, s >= 0 else { return "00:00" }
        return String(format: "%02d:%02d", Int(s) / 60, Int(s) % 60)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            bg
            Canvas { ctx, size in
                var y: CGFloat = 0
                while y < size.height {
                    ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                             with: .color(.black.opacity(0.25)))
                    y += 3
                }
            }
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                Text("$ dsplay --now-playing").opacity(0.6)
                Text("┌─ NOW PLAYING ─────────────────────────────┐").padding(.top, 18)
                Text("▸ \(ctx.track.title)").padding(.top, 8)
                Text("  \(ctx.track.artist)").opacity(0.75)
                Text("  \(ctx.track.album)").opacity(0.6)
                Text("[\(bar(ctx.progress))]  \(Int(ctx.progress * 100))%").padding(.top, 20)
                Text("\(ts(ctx.position)) / \(ts(ctx.duration))").padding(.top, 6)

                HStack(spacing: 20) {
                    termButton("[ << prev ]", filled: false, action: ctx.onPrev)
                    termButton(ctx.isPlaying ? "[ pause ]" : "[ play  ]",
                               filled: true, action: ctx.onPlayPause)
                    termButton("[ next >> ]", filled: false, action: ctx.onNext)
                }
                .padding(.top, 32)

                Text("└────────────────────────────────────────────┘")
                    .opacity(0.5).padding(.top, 48)
                Text("$ _").padding(.top, 12)
            }
            .font(.system(size: 14, design: .monospaced))
            .foregroundStyle(green)
            .shadow(color: green.opacity(0.4), radius: 4)
            .frame(maxWidth: 780, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(EdgeInsets(top: 48, leading: 64, bottom: 48, trailing: 64))

            SkinSwitcherView(tint: green, closeLabel: "ESC")
                .padding(.top, 32).padding(.trailing, 32)
        }
    }

    private func termButton(_ label: String, filled: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(filled ? bg : green)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(filled ? green : Color.clear)
                .overlay(Rectangle().stroke(green, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
