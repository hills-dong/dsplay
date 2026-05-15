import Foundation

actor AuthStore {
    private(set) var url: String = ""
    private(set) var user: String = ""
    private(set) var sid: String = ""

    var isAuthed: Bool { !sid.isEmpty }

    func set(url: String, user: String, sid: String) {
        self.url = url; self.user = user; self.sid = sid
    }

    func clear() { url = ""; user = ""; sid = "" }
}
