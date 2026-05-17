import SwiftUI

/// Design tokens ported from web/src/styles/theme.css.
enum Theme {
    // Adaptive (light / dark) — matches the native Music app in both modes.
    // Mapped to the equivalent semantic system color on each platform.
    #if os(macOS)
    static let ink       = Color(nsColor: .labelColor)
    static let mute      = Color(nsColor: .secondaryLabelColor)
    static let accent    = Color(nsColor: .systemRed)      // brighter in dark
    static let paper     = Color(nsColor: .windowBackgroundColor)
    static let coverBG   = Color(nsColor: .quaternaryLabelColor)
    /// Solid backing for the main content column — white in light mode,
    /// near-black in dark (matches Apple Music; only the chrome is glass).
    static let contentBG = Color(nsColor: .textBackgroundColor)
    #else
    static let ink       = Color(uiColor: .label)
    static let mute      = Color(uiColor: .secondaryLabel)
    static let accent    = Color(uiColor: .systemRed)
    static let paper     = Color(uiColor: .systemBackground)
    static let coverBG   = Color(uiColor: .quaternaryLabel)
    static let contentBG = Color(uiColor: .systemBackground)
    #endif

    static let titlebarH: CGFloat = 28
    static let topnavH: CGFloat = 56
    static let playerbarH: CGFloat = 76
    static let maxW: CGFloat = 960
    #if os(iOS)
    /// Tighter horizontal gutter on phones — 32 wastes a third of the width.
    static let padX: CGFloat = 16
    #else
    static let padX: CGFloat = 32
    #endif

    /// System (SF) font — matches the native Music app. Name kept as `serif`
    /// so existing call sites need no changes; italics dropped for the
    /// cleaner native look.
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        Font.system(size: size, weight: weight)
    }

    static func mono(_ size: CGFloat) -> Font {
        Font.system(size: size, design: .monospaced)
    }

    /// Small-caps label font (sans, tracked, uppercased at the call site).
    static func label(_ size: CGFloat = 11) -> Font {
        Font.system(size: size, weight: .regular).width(.standard)
    }
}

/// Reusable ".label" text style: 11px sans, 0.15em tracking, uppercase, muted.
struct LabelText: View {
    let text: String
    var size: CGFloat = 11
    var color: Color = Theme.mute
    init(_ text: String, size: CGFloat = 11, color: Color = Theme.mute) {
        self.text = text; self.size = size; self.color = color
    }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: size))
            .tracking(size * 0.15)
            .foregroundStyle(color)
    }
}

/// m:ss formatter shared by every view that shows playback time.
func fmtTime(_ s: Double) -> String {
    guard s.isFinite, s >= 0 else { return "0:00" }
    let m = Int(s) / 60
    let r = Int(s) % 60
    return String(format: "%d:%02d", m, r)
}
