import Foundation

/// Routes incoming JSON messages from the WebView to typed Swift handlers.
final class BridgeRouter {
    typealias Handler = (Data) async throws -> Data?   // returns response payload JSON or nil

    private var handlers: [String: Handler] = [:]

    func register(_ type: String, handler: @escaping Handler) {
        handlers[type] = handler
    }

    /// Dispatches the request envelope. Returns the response envelope bytes to send back to JS.
    /// Never throws — failures are turned into error envelopes.
    func dispatch(_ envelopeJSON: Data) async -> Data {
        guard let env = try? JSONSerialization.jsonObject(with: envelopeJSON) as? [String: Any],
              let kind = env["kind"] as? String, kind == "request",
              let requestId = env["requestId"] as? String,
              let message = env["message"] as? [String: Any],
              let type = message["type"] as? String,
              let payload = message["payload"]
        else {
            return Self.encodeError(requestId: "?", kind: "Unknown", message: "invalid envelope")
        }

        guard let handler = handlers[type] else {
            return Self.encodeError(requestId: requestId, kind: "Unknown", message: "no handler for \(type)")
        }

        do {
            let payloadData = try JSONSerialization.data(withJSONObject: payload)
            let responsePayload = try await handler(payloadData) ?? "{}".data(using: .utf8)!
            let payloadObj = (try? JSONSerialization.jsonObject(with: responsePayload)) ?? [:]
            let responseEnv: [String: Any] = [
                "kind": "response",
                "requestId": requestId,
                "ok": true,
                "message": ["type": type, "payload": payloadObj]
            ]
            return (try? JSONSerialization.data(withJSONObject: responseEnv))
                ?? Self.encodeError(requestId: requestId, kind: "Unknown", message: "encode failed")
        } catch let e as BridgeHandlerError {
            return Self.encodeError(requestId: requestId, kind: e.kind, message: e.message, code: e.code)
        } catch {
            return Self.encodeError(requestId: requestId, kind: "Unknown", message: String(describing: error))
        }
    }

    private static func encodeError(requestId: String, kind: String, message: String, code: Int? = nil) -> Data {
        var err: [String: Any] = ["kind": kind, "message": message]
        if let code { err["code"] = code }
        let env: [String: Any] = ["kind": "response", "requestId": requestId, "ok": false, "error": err]
        return (try? JSONSerialization.data(withJSONObject: env)) ?? Data("{}".utf8)
    }
}

/// Typed error that bridge handlers can throw to produce a structured error response.
struct BridgeHandlerError: Error {
    let kind: String         // matches BridgeErrorKind in shared/ipc-schema.ts
    let message: String
    let code: Int?
    init(kind: String, message: String, code: Int? = nil) {
        self.kind = kind; self.message = message; self.code = code
    }
}
