import Foundation

struct StoredCredentials: Codable, Equatable {
    let url: String
    let user: String
    let password: String
}

/// Persists DSM credentials in `~/Library/Application Support/DSPlay/credentials.json`
/// with file mode 0600. Type name retained as `KeychainService` to avoid churn at
/// call sites; the implementation is plain file I/O — no Keychain, no permission
/// dialog on every rebuild (each unsigned rebuild was a "different app" to the
/// system Keychain, hence the prompt loop).
enum KeychainService {
    static let service = "app.dsplay"
    static let account = "dsm-credentials"

    private static func storageURL(service: String, account: String) throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = base.appendingPathComponent("DSPlay", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        }
        // Filename combines service+account so tests with custom keys don't
        // collide with the default credentials file.
        let suffix = (service == self.service && account == self.account)
            ? "credentials"
            : "credentials.\(service).\(account)"
        return dir.appendingPathComponent("\(suffix).json")
    }

    static func save(_ creds: StoredCredentials, service: String = service, account: String = account) throws {
        let url = try storageURL(service: service, account: account)
        let data = try JSONEncoder().encode(creds)
        try data.write(to: url, options: [.atomic])
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: url.path
        )
    }

    static func load(service: String = service, account: String = account) throws -> StoredCredentials? {
        let url = try storageURL(service: service, account: account)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(StoredCredentials.self, from: data)
    }

    static func clear(service: String = service, account: String = account) throws {
        let url = try storageURL(service: service, account: account)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
