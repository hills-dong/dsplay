#if os(iOS)
import SwiftUI

/// Full-screen Now Playing for iOS — the standard Apple-Music layout (no
/// skins/themes), with swipe-down-to-dismiss.
struct NowPlayingSheet: View {
    @Environment(UIState.self) private var ui
    @State private var dragY: CGFloat = 0

    var body: some View {
        IOSNowPlayingView()
            .offset(y: dragY)
            .animation(.interactiveSpring, value: dragY)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { v in
                        // Only track clearly-vertical downward drags so the
                        // scrubber / volume sliders keep working.
                        if v.translation.height > 0,
                           v.translation.height > abs(v.translation.width) {
                            dragY = v.translation.height
                        }
                    }
                    .onEnded { v in
                        if v.translation.height > 140,
                           v.translation.height > abs(v.translation.width) {
                            ui.nowPlayingOpen = false
                        } else {
                            withAnimation(.smooth) { dragY = 0 }
                        }
                    }
            )
            .sheet(isPresented: Binding(
                get: { ui.queueOpen },
                set: { ui.queueOpen = $0 }
            )) {
                iOSQueueSheet()
            }
    }
}
#endif
