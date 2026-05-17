#if os(macOS)
import SwiftUI

/// Manual split layout — no NavigationSplitView. The sidebar width and the
/// queue column are fully under our control, and the player bar is a
/// top-level floating element completely outside the navigation hierarchy,
/// so it can never be squeezed, overlapped, or hidden by a detail push.
struct MainShellView: View {
    @Environment(AppModel.self) private var app
    @Environment(UIState.self) private var ui

    @State private var selection: SidebarSelection = .search
    @State private var path = NavigationPath()
    @State private var sidebarVisible = true
    @State private var playlists: [PlaylistDTO] = []
    @State private var showAccount = false

    private let sidebarWidth: CGFloat = 232

    var body: some View {
        ZStack(alignment: .bottom) {
            // ----- main row: sidebar | content | queue -----
            HStack(spacing: 0) {
                if sidebarVisible {
                    sidebar
                        .frame(width: sidebarWidth)
                        .transition(.move(edge: .leading))
                    Divider()
                }

                NavigationStack(path: $path) {
                    content
                        .navigationDestination(for: Route.self) { routeDestination($0) }
                        .toolbar(removing: .title)
                        // Frosted top bar (Apple Music) instead of a fully
                        // see-through title bar.
                        .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
                        .toolbarBackground(.regularMaterial, for: .windowToolbar)
                        .toolbar {
                            ToolbarItem(placement: .navigation) {
                                Button {
                                    withAnimation(.smooth) { sidebarVisible.toggle() }
                                } label: { Image(systemName: "sidebar.left") }
                                .help("Toggle Sidebar")
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                // Near-opaque adaptive surface — only the sidebar / player bar
                // stay translucent (Apple Music), and the whole view tree
                // isn't reblended against the desktop (keeps scrolling smooth).
                // Fixed readable scrim — content must stay legible and is
                // intentionally NOT tied to the glass slider.
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.55))
                // Reserve room so list rows can scroll clear of the floating
                // bar. A transparent spacer (not the bar itself) — safe across
                // navigation pushes.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: app.player.currentTrack != nil ? 88 : 0)
                }

                if ui.queueOpen {
                    Divider()
                    QueueDrawerView()
                        .frame(width: 300)
                        .background(Color(nsColor: .windowBackgroundColor)
                            .opacity(ui.glassScrim))
                        .transition(.move(edge: .trailing))
                }
            }

            // ----- floating player bar (top level, never tied to nav) -----
            if app.player.currentTrack != nil {
                PlayerBarView(openNowPlaying: { ui.nowPlayingOpen = true })
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                    // Clear of the sidebar; centered within the content region.
                    .padding(.leading, sidebarVisible ? sidebarWidth + 1 : 0)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay {
            if ui.nowPlayingOpen {
                NowPlayingView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    .zIndex(50)
            }
        }
        .animation(.smooth(duration: 0.25), value: sidebarVisible)
        .animation(.smooth(duration: 0.25), value: ui.queueOpen)
        .animation(.smooth(duration: 0.3), value: app.player.currentTrack?.id)
        .animation(.smooth(duration: 0.28), value: ui.nowPlayingOpen)
        .onChange(of: selection) { path = NavigationPath() }
        .task {
            if playlists.isEmpty {
                playlists = (try? await app.synology.listPlaylists()) ?? []
            }
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("DS MUSIC").font(.system(size: 22, weight: .bold))
                Text(".").font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, 14)

            // Custom rows (not List) so the selected highlight is always the
            // theme color — macOS List sidebar selection ignores `.tint`.
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    navRow("Search", "magnifyingglass", .search)

                    sectionHeader("Library")
                    navRow("Artists", "music.mic", .artists)
                    navRow("Albums", "square.stack", .albums)

                    sectionHeader("Playlists")
                    navRow("All Playlists", "music.note.list", .allPlaylists)
                    ForEach(playlists) { pl in
                        let name = friendlyPlaylistName(pl.name)
                        navRow(name, "music.note",
                               .playlist(id: pl.id, name: name))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }
            .scrollContentBackground(.hidden)
            .thinScrollbars()

            glassSlider
            themeSwitcher
            accountFooter
        }
        // User-tunable scrim over the window vibrancy (0 = fully transparent).
        .background(Color(nsColor: .windowBackgroundColor).opacity(ui.glassScrim))
    }

    private var glassSlider: some View {
        VStack(spacing: 4) {
            Divider()
            HStack(spacing: 8) {
                Image(systemName: "circle.dotted")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Text("Glass")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, alignment: .leading)
                Slider(
                    value: Binding(
                        // Left = solid, right = fully transparent (max glass).
                        get: { 1 - ui.glassScrim },
                        set: { ui.glassScrim = 1 - $0 }
                    ),
                    in: 0...1
                )
                .controlSize(.small)
                .tint(Theme.accent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
        }
    }

    private var themeSwitcher: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                // Single button — cycles System → Light → Dark.
                let all = AppAppearance.allCases
                let i = all.firstIndex(of: ui.appearance) ?? 0
                ui.appearance = all[(i + 1) % all.count]
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: ui.appearance.symbol)
                        .font(.system(size: 13))
                        .frame(width: 20)
                    Text("Appearance")
                        .font(.system(size: 12))
                    Spacer(minLength: 0)
                    Text(ui.appearance.label)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Switch appearance: System / Light / Dark")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }

    private func navRow(_ title: String, _ symbol: String,
                        _ sel: SidebarSelection) -> some View {
        let isSel = selection == sel
        return Button {
            selection = sel
        } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 13))
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 13, weight: isSel ? .semibold : .regular))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSel ? Color.white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSel ? Theme.accent : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var accountHost: String {
        URL(string: app.nasURL)?.host ?? app.nasURL
    }

    private var accountFooter: some View {
        VStack(spacing: 0) {
            Divider()
            Button { showAccount.toggle() } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(app.user.isEmpty ? "Account" : app.user)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                        Text(accountHost)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showAccount, arrowEdge: .top) {
                accountPopover
            }
        }
    }

    private var accountPopover: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.user).font(.system(size: 14, weight: .semibold))
                    Text("Synology Audio Station")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            Divider()
            row("Server", app.nasURL)
            row("User", app.user)
            Divider()
            Button(role: .destructive) {
                showAccount = false
                Task { await app.logout() }
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.accent)
        }
        .padding(18)
        .frame(width: 280)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .frame(width: 56, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
    }

    // MARK: Detail content

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .search:       SearchView()
        case .artists:      ArtistsView()
        case .albums:       AlbumsView()
        case .allPlaylists: PlaylistsView()
        case .playlist(let id, _):
            PlaylistDetailView(playlistId: id)
        }
    }

}
#endif
