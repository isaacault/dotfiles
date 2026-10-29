import Cocoa
import WebKit

final class Panel: NSPanel {
    override var canBecomeKey: Bool { true }
    override func keyDown(with event: NSEvent) { NSApp.terminate(nil) }
}

final class Web: WKWebView {
    override func keyDown(with event: NSEvent) { NSApp.terminate(nil) }
}

final class Delegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, NSWindowDelegate {
    var panel: Panel!
    func applicationDidFinishLaunching(_ n: Notification) {
        let dir = (CommandLine.arguments[0] as NSString).deletingLastPathComponent
        let html = URL(fileURLWithPath: dir).appendingPathComponent("CHEATSHEET.html")
        let size = NSSize(width: 860, height: 560)
        let screen = NSScreen.main!.visibleFrame
        let rect = NSRect(x: screen.midX - size.width / 2, y: screen.midY - size.height / 2,
                          width: size.width, height: size.height)
        panel = Panel(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.delegate = self
        let web = Web(frame: NSRect(origin: .zero, size: size))
        web.navigationDelegate = self
        web.setValue(false, forKey: "drawsBackground")
        web.wantsLayer = true
        web.layer?.cornerRadius = 14
        web.layer?.masksToBounds = true
        web.loadFileURL(html, allowingReadAccessTo: html.deletingLastPathComponent())
        panel.contentView = web
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    func webView(_ web: WKWebView, didFinish _: WKNavigation!) {
        web.evaluateJavaScript("document.documentElement.scrollHeight") { [self] h, _ in
            guard let h = h as? CGFloat, let screen = NSScreen.main?.visibleFrame else { return }
            let height = min(h, screen.height - 40)
            let rect = NSRect(x: screen.midX - panel.frame.width / 2, y: screen.midY - height / 2,
                              width: panel.frame.width, height: height)
            panel.setFrame(rect, display: true)
        }
    }
    func windowDidResignKey(_ n: Notification) { NSApp.terminate(nil) }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = Delegate()
app.delegate = delegate
app.run()
