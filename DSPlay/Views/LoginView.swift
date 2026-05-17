import SwiftUI

struct LoginView: View {
    @Environment(AppModel.self) private var app

    @State private var url = ""
    @State private var user = ""
    @State private var password = ""
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("DS MUSIC").font(Theme.serif(34, weight: .bold))
                Text(".").font(Theme.serif(34, weight: .bold)).foregroundStyle(Theme.accent)
            }
            .padding(.bottom, 6)
            Text("Sign in to your library")
                .font(Theme.serif(17, italic: true))
                .foregroundStyle(.secondary)
                .padding(.bottom, 28)

            VStack(spacing: 14) {
                glassField("NAS URL", systemImage: "network", text: $url)
                glassField("Username", systemImage: "person", text: $user)
                glassField("Password", systemImage: "lock", text: $password, secure: true)

                if let error {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: submit) {
                    Text(busy ? "Connecting…" : "Connect")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .disabled(busy || url.isEmpty)
                .padding(.top, 6)
            }
            .frame(maxWidth: 340)
            .padding(28)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .onSubmit(submit)
    }

    @ViewBuilder
    private func glassField(_ label: String, systemImage: String,
                            text: Binding<String>, secure: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Group {
                if secure { SecureField(label, text: text) }
                else { TextField(label, text: text) }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 14))
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(label == "NAS URL" ? .URL : .default)
            #endif
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .glassEffect(.regular, in: .capsule)
    }

    private func submit() {
        guard !busy, !url.isEmpty else { return }
        busy = true
        error = nil
        Task {
            do {
                try await app.login(url: url, user: user, password: password)
            } catch let e as BridgeHandlerError {
                error = e.message
            } catch {
                self.error = error.localizedDescription
            }
            busy = false
        }
    }
}
