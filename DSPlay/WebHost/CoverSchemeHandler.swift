import Foundation
import WebKit

final class CoverSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "dsplaycover"

    private let synology: SynologyClient
    init(synology: SynologyClient) { self.synology = synology }

    /// Build a URL the WebView can put into <img src>.
    static func url(forSongId songId: String) -> URL {
        URL(string: "\(scheme)://song/\(songId)")!
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        guard let requestURL = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }
        let songId = String(requestURL.path.dropFirst())
        Task { [weak self] in
            guard let self else {
                urlSchemeTask.didFailWithError(URLError(.cancelled))
                return
            }
            guard let upstream = await synology.coverURL(songId: songId) else {
                urlSchemeTask.didFailWithError(URLError(.badURL))
                return
            }
            do {
                let (data, response) = try await URLSession.shared.data(from: upstream)
                let mime = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type") ?? "image/jpeg"
                let proxied = HTTPURLResponse(
                    url: requestURL,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: [
                        "Content-Type": mime,
                        "Content-Length": String(data.count),
                        "Cache-Control": "public, max-age=86400",
                    ]
                )!
                urlSchemeTask.didReceive(proxied)
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
            } catch {
                urlSchemeTask.didFailWithError(error)
            }
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {}
}
