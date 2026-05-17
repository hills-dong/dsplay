#if os(iOS)
import SwiftUI

/// iOS top-level shell. Compact width (iPhone, iPad slide-over) → tab bar.
/// Regular width (iPad) → split-view shell. The macOS `MainShellView` is not
/// compiled on iOS; this is its iOS-native replacement.
struct iOSRootShell: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(UIState.self) private var ui

    var body: some View {
        Group {
            if hSize == .regular {
                iPadSplitShell()
            } else {
                iPhoneTabShell()
            }
        }
        .tint(Theme.accent)
        .preferredColorScheme(ui.appearance.colorScheme)
    }
}
#endif
