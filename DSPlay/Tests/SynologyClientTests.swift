import Testing
import Foundation
@testable import DSPlay

// MARK: - MockURLProtocol

/// A URLProtocol subclass that intercepts all requests and delegates to a static responder closure.
final class MockURLProtocol: URLProtocol {
    /// Set this before each test. Returns (Data, HTTPURLResponse) or throws.
    nonisolated(unsafe) static var responder: ((URL) throws -> (Data, HTTPURLResponse))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            guard let responder = MockURLProtocol.responder else {
                throw URLError(.resourceUnavailable)
            }
            let (data, response) = try responder(url)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Helpers

private func mockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private func mockResponse(for url: URL, json: String, status: Int = 200) throws -> (Data, HTTPURLResponse) {
    let data = Data(json.utf8)
    let resp = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    return (data, resp)
}

// MARK: - Test Suite

@Suite("SynologyClient")
struct SynologyClientTests {

    @Test func test_login_stores_sid_on_success() async throws {
        MockURLProtocol.responder = { url in
            try mockResponse(for: url, json: #"{"success":true,"data":{"sid":"SID123"}}"#)
        }
        let client = SynologyClient(session: mockSession())
        try await client.login(url: "http://nas.local:5000", user: "alice", password: "pass")
        let sid = await client.authStore.sid
        #expect(sid == "SID123")
        let storedUser = await client.authStore.user
        #expect(storedUser == "alice")
    }

    @Test func test_login_throws_bridge_error_on_failure() async throws {
        MockURLProtocol.responder = { url in
            try mockResponse(for: url, json: #"{"success":false,"error":{"code":400}}"#)
        }
        let client = SynologyClient(session: mockSession())
        var caught: BridgeHandlerError?
        do {
            try await client.login(url: "http://nas.local:5000", user: "alice", password: "wrong")
        } catch let e as BridgeHandlerError {
            caught = e
        }
        #expect(caught != nil)
        #expect(caught?.kind == "Synology")
        #expect(caught?.code == 400)
    }

    @Test func test_search_parses_songs() async throws {
        // First call: login, second call: search
        var callCount = 0
        MockURLProtocol.responder = { url in
            callCount += 1
            if callCount == 1 {
                // Login response
                return try mockResponse(for: url, json: #"{"success":true,"data":{"sid":"SID_SEARCH"}}"#)
            } else {
                // Search response
                let json = """
                {
                  "success": true,
                  "data": {
                    "total": 1,
                    "songs": [{
                      "id": "song_1",
                      "title": "Test Track",
                      "path": "/music/test.mp3",
                      "additional": {
                        "song_tag": { "album": "Test Album", "artist": "Test Artist" },
                        "song_audio": { "duration": 210.5 }
                      }
                    }]
                  }
                }
                """
                return try mockResponse(for: url, json: json)
            }
        }
        let client = SynologyClient(session: mockSession())
        try await client.login(url: "http://nas.local:5000", user: "alice", password: "pass")
        let tracks = try await client.search(query: "Test", limit: 10)
        #expect(tracks.count == 1)
        #expect(tracks[0].id == "song_1")
        #expect(tracks[0].title == "Test Track")
        #expect(tracks[0].artist == "Test Artist")
        #expect(tracks[0].album == "Test Album")
        #expect(tracks[0].duration == 210.5)
        #expect(tracks[0].path == "/music/test.mp3")
    }

    @Test func test_session_expiry_triggers_silent_reauth() async throws {
        // Sequence: login → search (returns 105) → re-login → retry search (succeeds)
        var callCount = 0
        MockURLProtocol.responder = { url in
            callCount += 1
            switch callCount {
            case 1:
                // Initial login
                return try mockResponse(for: url, json: #"{"success":true,"data":{"sid":"OLD_SID"}}"#)
            case 2:
                // Search returns session expiry code 105
                return try mockResponse(for: url, json: #"{"success":false,"error":{"code":105}}"#)
            case 3:
                // Silent re-login
                return try mockResponse(for: url, json: #"{"success":true,"data":{"sid":"NEW_SID"}}"#)
            default:
                // Retry search succeeds
                let json = """
                {
                  "success": true,
                  "data": {
                    "total": 1,
                    "songs": [{"id": "s1", "title": "Song After Reauth", "path": null, "additional": null}]
                  }
                }
                """
                return try mockResponse(for: url, json: json)
            }
        }

        let savedCreds = StoredCredentials(url: "http://nas.local:5000", user: "alice", password: "pass")
        let client = SynologyClient(session: mockSession())
        client.savedCredentialsProvider = { savedCreds }

        try await client.login(url: "http://nas.local:5000", user: "alice", password: "pass")
        let tracks = try await client.search(query: "reauth", limit: 10)

        let finalSid = await client.authStore.sid
        #expect(finalSid == "NEW_SID")
        #expect(tracks.count == 1)
        #expect(tracks[0].title == "Song After Reauth")
    }
}
