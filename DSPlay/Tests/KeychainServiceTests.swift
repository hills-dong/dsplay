import Testing
import Foundation
@testable import DSPlay

private let testService = "app.dsplay.test"
private let testAccount = "ci-credstore-test"

@Suite("KeychainService (file-backed credentials store)")
struct KeychainServiceTests {

    init() throws {
        try? KeychainService.clear(service: testService, account: testAccount)
    }

    @Test func saveAndLoadRoundtrip() throws {
        let creds = StoredCredentials(url: "https://example.test", user: "alice", password: "s3cret")
        try KeychainService.save(creds, service: testService, account: testAccount)
        let loaded = try KeychainService.load(service: testService, account: testAccount)
        defer { try? KeychainService.clear(service: testService, account: testAccount) }
        #expect(loaded == creds)
    }

    @Test func loadReturnsNilWhenAbsent() throws {
        let loaded = try KeychainService.load(service: testService, account: testAccount)
        defer { try? KeychainService.clear(service: testService, account: testAccount) }
        #expect(loaded == nil)
    }

    @Test func saveOverwritesExisting() throws {
        let first = StoredCredentials(url: "https://a", user: "a", password: "1")
        let second = StoredCredentials(url: "https://b", user: "b", password: "2")
        try KeychainService.save(first, service: testService, account: testAccount)
        try KeychainService.save(second, service: testService, account: testAccount)
        defer { try? KeychainService.clear(service: testService, account: testAccount) }
        #expect(try KeychainService.load(service: testService, account: testAccount) == second)
    }
}
