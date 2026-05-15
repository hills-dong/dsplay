import Foundation

@MainActor
final class BridgeEvents {
    let server: BridgeServer
    init(server: BridgeServer) { self.server = server }

    func playerTimeUpdate(position: Double, duration: Double) {
        server.emit(eventType: "player.timeUpdate", payload: [
            "position": position, "duration": duration
        ])
    }

    func playerStateChange(state: String, track: [String: Any]? = nil) {
        var p: [String: Any] = ["state": state]
        if let track { p["track"] = track }
        server.emit(eventType: "player.stateChange", payload: p)
    }

    func playerEnded() { server.emit(eventType: "player.ended", payload: [:]) }
    func playerError(message: String) { server.emit(eventType: "player.error", payload: ["message": message]) }
    func authExpired() { server.emit(eventType: "auth.expired", payload: [:]) }
    func mediaKey(_ key: String) { server.emit(eventType: "mediaKey", payload: ["key": key]) }

    func queueUpdate(queue: [[String: Any]], index: Int, shuffle: Bool, repeatMode: String) {
        server.emit(eventType: "queue.update", payload: [
            "queue": queue,
            "index": index,
            "shuffle": shuffle,
            "repeat": repeatMode,
        ])
    }
}
