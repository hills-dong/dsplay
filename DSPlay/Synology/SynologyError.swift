import Foundation

/// Typed error raised by the Synology client / playback engine.
///
/// Formerly `BridgeHandlerError` in the (now removed) IPC bridge layer; the
/// type name is preserved so `SynologyClient`'s many throw sites compile
/// unchanged after the web/bridge stack was deleted.
struct BridgeHandlerError: Error {
    let kind: String         // "Network" | "Synology" | "NotAuthenticated" | "SessionExpired" | "Unknown"
    let message: String
    let code: Int?
    init(kind: String, message: String, code: Int? = nil) {
        self.kind = kind; self.message = message; self.code = code
    }
}

extension BridgeHandlerError: LocalizedError {
    var errorDescription: String? { message }
}
