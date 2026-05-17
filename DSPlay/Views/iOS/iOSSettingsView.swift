#if os(iOS)
import SwiftUI

/// iOS Settings tab — account + appearance (Apple-Music-style; no skins or
/// glass-scrim, those were macOS chrome concepts).
struct iOSSettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(UIState.self) private var ui

    private var accountHost: String {
        URL(string: app.nasURL)?.host ?? app.nasURL
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Server", value: accountHost)
                    LabeledContent("User", value: app.user)
                    Button(role: .destructive) {
                        Task { await app.logout() }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { ui.appearance },
                        set: { ui.appearance = $0 }
                    )) {
                        ForEach(AppAppearance.allCases) { a in
                            Text(a.label).tag(a)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
#endif
