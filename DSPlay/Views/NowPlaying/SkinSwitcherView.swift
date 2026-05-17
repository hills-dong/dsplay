import SwiftUI

struct SkinSwitcherView: View {
    @Environment(UIState.self) private var ui
    @State private var open = false
    // Kept for source-compat with the retro skins; styling is plain now.
    var tint: Color = .primary
    var closeLabel: String = "Close"

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack(spacing: 18) {
                plainIcon("paintpalette") {
                    withAnimation(.smooth) { open.toggle() }
                }
            }

            if open {
                HStack(spacing: 8) {
                    ForEach(Skin.allCases) { s in
                        Button {
                            ui.skin = s
                            withAnimation(.smooth) { open = false }
                        } label: {
                            VStack(spacing: 4) {
                                Text(s.preview).font(.system(size: 18, weight: .semibold))
                                Text(s.label).font(.system(size: 9))
                            }
                            .foregroundStyle(ui.skin == s ? Theme.accent : .primary)
                            .frame(width: 58, height: 58)
                            .background(
                                Color.gray.opacity(ui.skin == s ? 0.22 : 0.10),
                                in: .rect(cornerRadius: 10)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(.regularMaterial, in: .rect(cornerRadius: 14))
            }
        }
    }

    private func plainIcon(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(.primary)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
