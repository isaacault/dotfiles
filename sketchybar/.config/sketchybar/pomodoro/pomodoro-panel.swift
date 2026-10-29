import Cocoa
import WebKit

// Pomodoro history & settings panel. Reads ~/.local/state/sketchybar/pomodoro.{log,conf},
// hands them to panel.html, and writes settings back when the page saves.
// Build: swiftc -O pomodoro-panel.swift -o pomodoro-panel

let stateDir = NSString(string: "~/.local/state/sketchybar").expandingTildeInPath
let confKeys: Set<String> = ["focus_min", "short_min", "long_min", "sessions_per_long", "goal",
                             "chime", "invert", "banner"]

final class Panel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class Delegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKScriptMessageHandler,
    NSWindowDelegate
{
    var panel: Panel!
    var web: WKWebView!

    func applicationDidFinishLaunching(_ n: Notification) {
        let dir = (CommandLine.arguments[0] as NSString).deletingLastPathComponent
        let html = URL(fileURLWithPath: dir).appendingPathComponent("panel.html")
        let size = NSSize(width: 900, height: 720)
        let screen = NSScreen.main!.visibleFrame
        let rect = NSRect(x: screen.midX - size.width / 2, y: screen.midY - size.height / 2,
                          width: size.width, height: size.height)
        panel = Panel(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.delegate = self

        let controller = WKUserContentController()
        controller.add(self, name: "save")
        controller.add(self, name: "close")
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        web = WKWebView(frame: NSRect(origin: .zero, size: size), configuration: config)
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

    func read(_ name: String) -> String {
        (try? String(contentsOfFile: stateDir + "/" + name, encoding: .utf8)) ?? ""
    }

    func webView(_ web: WKWebView, didFinish _: WKNavigation!) {
        let payload = [read("pomodoro.log"), read("pomodoro.conf")]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else { return }
        // Optional first argument picks the starting tab: 0 Today, 1 Week, 2 Month, 3 Settings.
        let tab = CommandLine.arguments.count > 1 ? Int(CommandLine.arguments[1]) ?? 0 : 0
        web.evaluateJavaScript("init(\(json)); go(\(min(max(tab, 0), 3)))")
    }

    func userContentController(_ c: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "close" { NSApp.terminate(nil); return }
        guard let values = message.body as? [String: Any] else { return }
        var lines: [String] = []
        for (key, value) in values where confKeys.contains(key) {
            let text = "\(value)"
            // Only plain numbers and booleans reach the conf file the bar parses.
            guard text.range(of: "^[0-9a-z.]+$", options: .regularExpression) != nil else { continue }
            lines.append("\(key)=\(text)")
        }
        try? FileManager.default.createDirectory(atPath: stateDir, withIntermediateDirectories: true)
        try? (lines.sorted().joined(separator: "\n") + "\n")
            .write(toFile: stateDir + "/pomodoro.conf", atomically: true, encoding: .utf8)

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/sketchybar")
        p.arguments = ["--trigger", "pomodoro_settings"]
        try? p.run()
    }

    func windowDidResignKey(_ n: Notification) { NSApp.terminate(nil) }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = Delegate()
app.delegate = delegate
app.run()
