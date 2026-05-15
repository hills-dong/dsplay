import Foundation
import WebKit

/// Breaks the strong retain WKUserContentController → BridgeServer would otherwise create.
private final class WeakMessageHandlerProxy: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(_ delegate: WKScriptMessageHandler) { self.delegate = delegate }
    func userContentController(_ uc: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(uc, didReceive: message)
    }
}

/// Hooks the BridgeRouter into a WKWebView via WKScriptMessageHandler.
final class BridgeServer: NSObject, WKScriptMessageHandler {
    let router: BridgeRouter
    weak var webView: WKWebView?

    init(router: BridgeRouter) {
        self.router = router
    }

    static let messageHandlerName = "dsplay"

    /// Adds this server to the given config's userContentController and installs the JS-side receiver.
    func attach(to config: WKWebViewConfiguration) {
        config.userContentController.add(WeakMessageHandlerProxy(self), name: Self.messageHandlerName)
        // Also register a dedicated log channel for forwarding JS console/errors to NSLog.
        config.userContentController.add(WeakMessageHandlerProxy(self), name: "dsplay_log")

        let script = WKUserScript(source: """
        (function() {
          // Immediate breadcrumb so we know the user-script ran at all
          try { window.webkit.messageHandlers.dsplay_log.postMessage('user-script injected, URL=' + location.href); } catch(_){}
          if (window.__dsplay) return;
          window.__dsplay = {
            send: (envelope) => {
              window.webkit.messageHandlers.dsplay.postMessage(envelope);
            }
          };
          window.__dsplay_receive = (envelope) => {
            const handler = window.__dsplay_handler;
            if (typeof handler === "function") handler(envelope);
          };
          // Forward console + errors to native NSLog for headless debugging.
          var native = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.dsplay_log;
          function logToNative(level, args) {
            try {
              var msg = Array.prototype.slice.call(args).map(function(a){
                try { return typeof a === 'string' ? a : JSON.stringify(a); } catch(_) { return String(a); }
              }).join(' ');
              if (native) native.postMessage(level + ': ' + msg);
            } catch(_) {}
          }
          ['log','warn','error','info','debug'].forEach(function(level){
            var orig = console[level];
            console[level] = function(){ logToNative(level, arguments); orig && orig.apply(console, arguments); };
          });
          window.addEventListener('error', function(ev){
            logToNative('UNCAUGHT', ['ERROR', ev.message, 'at', ev.filename + ':' + ev.lineno + ':' + ev.colno, ev.error && ev.error.stack || '']);
          }, true);
          window.addEventListener('unhandledrejection', function(ev){
            logToNative('UNHANDLED_REJECTION', [ev.reason && (ev.reason.stack || ev.reason.message) || String(ev.reason)]);
          });
        })();
        """, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        config.userContentController.addUserScript(script)
    }

    func userContentController(_ uc: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "dsplay_log" {
            NSLog("[DSPlay/JS] %@", String(describing: message.body))
            return
        }
        guard message.name == Self.messageHandlerName else { return }
        let object = message.body
        guard let data = try? JSONSerialization.data(withJSONObject: object) else { return }

        Task { [weak self] in
            guard let self else { return }
            let responseData = await router.dispatch(data)
            await MainActor.run {
                self.deliverToJS(responseData)
            }
        }
    }

    @MainActor
    func emit(eventType: String, payload: [String: Any]) {
        let env: [String: Any] = ["kind": "event", "message": ["type": eventType, "payload": payload]]
        guard let data = try? JSONSerialization.data(withJSONObject: env) else { return }
        deliverToJS(data)
    }

    @MainActor
    private func deliverToJS(_ envelopeData: Data) {
        guard let webView else { return }
        guard let json = String(data: envelopeData, encoding: .utf8) else { return }
        // We pass the raw JSON string as an argument and parse it on the JS side.
        // This avoids any string-interpolation injection risk.
        let script = "window.__dsplay_receive(JSON.parse(envelope));"
        webView.callAsyncJavaScript(
            script,
            arguments: ["envelope": json],
            in: nil,
            in: .page
        ) { _ in }
    }
}
