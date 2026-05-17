import SwiftUI

/// The Terminal / Winamp / Vinyl skins are fixed-size desktop art pieces
/// (panels/discs/ASCII boxes 500–1100pt wide). Rather than redraw each for a
/// phone, render them at their native desktop design size and uniformly
/// scale-to-fit the screen on iOS. macOS is a passthrough (unchanged).
struct SkinFit<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        #if os(iOS)
        GeometryReader { geo in
            let designW: CGFloat = 1200
            let designH: CGFloat = 900
            let scale = min(geo.size.width / designW,
                            geo.size.height / designH)
            content
                .frame(width: designW, height: designH)
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        #else
        content
        #endif
    }
}
