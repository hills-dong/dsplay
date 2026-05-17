import Observation
import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#endif

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max"
        case .dark:   return "moon"
        }
    }
    /// SwiftUI color scheme override (nil = follow system) — used by the iOS
    /// `WindowGroup` via `.preferredColorScheme`.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    #if os(macOS)
    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light:  return NSAppearance(named: .aqua)
        case .dark:   return NSAppearance(named: .darkAqua)
        }
    }
    #endif
}

enum Skin: String, CaseIterable, Identifiable {
    case editorial, terminal, winamp, vinyl
    var id: String { rawValue }
    var label: String {
        switch self {
        case .editorial: return "Editorial"
        case .terminal:  return "Terminal"
        case .winamp:    return "Winamp"
        case .vinyl:     return "Vinyl"
        }
    }
    var preview: String {
        switch self {
        case .editorial: return "E"
        case .terminal:  return "T"
        case .winamp:    return "W"
        case .vinyl:     return "V"
        }
    }
}

/// Observable UI state ported from web/src/stores/ui.ts. The skin choice is
/// persisted to UserDefaults (replacing localStorage).
@MainActor
@Observable
final class UIState {
    var queueOpen: Bool = false
    var nowPlayingOpen: Bool = false
    var skin: Skin {
        didSet { UserDefaults.standard.set(skin.rawValue, forKey: Self.skinKey) }
    }
    var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Self.appearanceKey)
            applyAppearance()
        }
    }
    /// Sidebar / player-bar / queue scrim opacity over the window vibrancy.
    /// 0 = fully transparent (max glass), 1 = opaque. The content column
    /// keeps its own fixed readable scrim and is NOT affected.
    var glassScrim: Double {
        didSet { UserDefaults.standard.set(glassScrim, forKey: Self.glassKey) }
    }

    private static let skinKey = "dsplay.skin"
    private static let appearanceKey = "dsplay.appearance"
    private static let glassKey = "dsplay.glassScrim"

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.skinKey)
        self.skin = raw.flatMap(Skin.init(rawValue:)) ?? .editorial
        let a = UserDefaults.standard.string(forKey: Self.appearanceKey)
        self.appearance = a.flatMap(AppAppearance.init(rawValue:)) ?? .system
        let g = UserDefaults.standard.object(forKey: Self.glassKey) as? Double
        self.glassScrim = g ?? 0.0   // 0 = fully transparent chrome (max glass)
    }

    /// Apply the chosen appearance to the whole app (nil = follow system).
    /// On macOS this drives `NSApp.appearance`; on iOS appearance is applied
    /// via `.preferredColorScheme(appearance.colorScheme)` on the scene.
    func applyAppearance() {
        #if os(macOS)
        NSApp.appearance = appearance.nsAppearance
        #endif
    }
}
