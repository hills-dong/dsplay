import SwiftUI
import AVKit

/// Wraps the system `AVRoutePickerView` — the same AirPlay output-device
/// picker Apple Music uses. Selecting a route applies to the app's AVPlayer
/// audio automatically.
#if os(macOS)
struct RoutePickerButton: NSViewRepresentable {
    var tint: PlatformColor = .secondaryLabelColor

    func makeNSView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView()
        v.isRoutePickerButtonBordered = false
        v.setRoutePickerButtonColor(tint, for: .normal)
        v.setRoutePickerButtonColor(PlatformColor(Theme.accent), for: .active)
        return v
    }

    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {
        nsView.setRoutePickerButtonColor(tint, for: .normal)
        nsView.setRoutePickerButtonColor(PlatformColor(Theme.accent), for: .active)
    }
}
#else
struct RoutePickerButton: UIViewRepresentable {
    var tint: PlatformColor = .secondaryLabel

    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView()
        v.tintColor = tint
        v.activeTintColor = PlatformColor(Theme.accent)
        return v
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = tint
        uiView.activeTintColor = PlatformColor(Theme.accent)
    }
}
#endif
