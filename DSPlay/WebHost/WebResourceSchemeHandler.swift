import Foundation
import WebKit
import UniformTypeIdentifiers

/// Serves the bundled WebDist directory through a custom `dsplay://` URL scheme.
///
/// We use this instead of `file://` because WKWebView's file:// origin treats every
/// resource as cross-origin (it has no schema host), which blocks
/// `<script type="module">` from executing. A custom scheme gets a proper origin
/// (`dsplay://app/`) that satisfies the modules' implicit CORS check.
final class WebResourceSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "dsplay"
    static let host = "app"

    private let rootDirectory: URL

    init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
    }

    /// Build the entry-point URL the WebView should load.
    /// We load `dsplay://app/` (root) so @solidjs/router sees the path as `/`,
    /// which matches the default route. The handler maps `/` → `index.html`.
    static var entryURL: URL? {
        URL(string: "\(scheme)://\(host)/")
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        guard let requestURL = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }
        // Strip leading "/" then resolve relative to the root.
        // Map "/" (or empty) and any unknown SPA path → index.html so the
        // SolidJS router decides the route from `location.pathname`.
        var relativePath = requestURL.path.hasPrefix("/") ? String(requestURL.path.dropFirst()) : requestURL.path
        if relativePath.isEmpty || relativePath == "index.html" {
            relativePath = "index.html"
        }
        var fileURL = rootDirectory.appendingPathComponent(relativePath)

        // SPA fallback: if the requested path doesn't map to a real file AND it
        // doesn't look like a sub-resource (.js/.css/.png etc.), serve index.html
        // so the SolidJS router takes over.
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let ext = fileURL.pathExtension.lowercased()
            let knownAssetExt: Set<String> = ["js", "mjs", "css", "json", "map",
                                              "png", "jpg", "jpeg", "gif", "svg",
                                              "woff", "woff2", "ttf", "otf", "ico"]
            if ext.isEmpty || !knownAssetExt.contains(ext) {
                fileURL = rootDirectory.appendingPathComponent("index.html")
            }
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            NSLog("[DSPlay] scheme handler: 404 \(requestURL.path)")
            urlSchemeTask.didReceive(
                HTTPURLResponse(url: requestURL, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
            )
            urlSchemeTask.didFinish()
            return
        }

        let mime = mimeType(for: fileURL.pathExtension)
        let response = HTTPURLResponse(
            url: requestURL,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": mime,
                "Content-Length": String(data.count),
                "Access-Control-Allow-Origin": "*",
            ]
        )!
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {
        // No long-lived work to cancel — synchronous file reads above.
    }

    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html", "htm": return "text/html; charset=utf-8"
        case "js", "mjs":   return "application/javascript; charset=utf-8"
        case "css":         return "text/css; charset=utf-8"
        case "json":        return "application/json; charset=utf-8"
        case "svg":         return "image/svg+xml"
        case "png":         return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif":         return "image/gif"
        case "woff":        return "font/woff"
        case "woff2":       return "font/woff2"
        case "ttf":         return "font/ttf"
        case "otf":         return "font/otf"
        case "ico":         return "image/x-icon"
        case "map":         return "application/json"
        default:            return "application/octet-stream"
        }
    }
}
