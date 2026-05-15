import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let item: NSStatusItem
    private weak var engine: PlaybackEngine?
    private weak var events: BridgeEvents?
    private let onShowWindow: () -> Void

    private let titleItem: NSMenuItem
    private let playPauseItem: NSMenuItem
    private let nextItem: NSMenuItem
    private let prevItem: NSMenuItem

    init(engine: PlaybackEngine, events: BridgeEvents, onShowWindow: @escaping () -> Void) {
        self.engine = engine
        self.events = events
        self.onShowWindow = onShowWindow

        let statusBar = NSStatusBar.system
        self.item = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        self.item.button?.title = "♪"
        self.item.button?.toolTip = "DSPlay"

        // Build menu
        let menu = NSMenu()
        self.titleItem = NSMenuItem(title: "Nothing playing", action: nil, keyEquivalent: "")
        self.titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        self.playPauseItem = NSMenuItem(title: "Play",  action: #selector(togglePlay), keyEquivalent: "")
        self.nextItem     = NSMenuItem(title: "Next ⏭", action: #selector(next),       keyEquivalent: "")
        self.prevItem     = NSMenuItem(title: "Prev ⏮", action: #selector(prev),       keyEquivalent: "")
        menu.addItem(playPauseItem)
        menu.addItem(nextItem)
        menu.addItem(prevItem)
        menu.addItem(.separator())

        let showItem = NSMenuItem(title: "Show DSPlay", action: #selector(showWindow), keyEquivalent: "n")
        showItem.keyEquivalentModifierMask = [.command]
        menu.addItem(showItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        self.item.menu = menu

        super.init()

        // Set targets after super.init (so @objc methods resolve)
        for it in [playPauseItem, nextItem, prevItem, showItem] { it.target = self }

        // Subscribe to playback state changes by polling — we don't have an event bus to Swift
        // since events go to the WebView. Poll every 500ms for the title + button label.
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        refresh()
    }

    // MARK: actions

    @objc func togglePlay() {
        engine?.toggle()
        refresh()
    }

    @objc func next() {
        Task { @MainActor in try? await engine?.next() }
    }

    @objc func prev() {
        Task { @MainActor in try? await engine?.prev() }
    }

    @objc func showWindow() {
        onShowWindow()
    }

    // MARK: state sync

    private func refresh() {
        let track = engine?.currentTrack
        if let track {
            let display = "\(track.title) — \(track.artist)"
            titleItem.title = display.count > 60 ? String(display.prefix(58)) + "…" : display
            item.button?.title = "♪"
            item.button?.toolTip = "DSPlay · \(track.title)"
            playPauseItem.title = (engine?.isPlaying ?? false) ? "Pause" : "Play"
        } else {
            titleItem.title = "Nothing playing"
            item.button?.title = "♪"
            item.button?.toolTip = "DSPlay"
            playPauseItem.title = "Play"
        }
        let hasQueue = (engine?.queue.count ?? 0) > 0
        nextItem.isEnabled = hasQueue
        prevItem.isEnabled = hasQueue
        playPauseItem.isEnabled = hasQueue
    }
}
