// SPDX-License-Identifier: MIT
// wifi-ssid: print the name (SSID) of the Wi-Fi network this Mac is on.
//
// Since macOS 14.4 the SSID is hidden from every command-line tool (ipconfig,
// networksetup, scutil, system_profiler, wdutil without root) unless the
// caller holds Location Services permission. This helper asks for that
// permission once and reads the name through CoreWLAN. It has to run from the
// .app bundle that scripts/build-swift-tools.sh builds: the permission is tied
// to the bundle id in Info.plist, and the dialog needs the usage text there.
// To grant it, launch the bundle once and click Allow:
//   open ~/.config/sketchybar/wifi-ssid/wifi-ssid.app
// CoreWLAN checks the permission of the process macOS holds *responsible*:
// started from a shell or by sketchybar, the helper is attributed to that
// launcher and gets no name even though CoreLocation reports it authorized.
// Launched through open(1) it is its own responsible process, so the widget
// (and any test by hand) must start it that way:
//   open -n -W --stdout /tmp/ssid ~/.config/sketchybar/wifi-ssid/wifi-ssid.app --args --debug; cat /tmp/ssid
// If System Settings > Privacy & Security > Location Services then lists
// wifi-ssid switched off, switch it on. A rebuild changes the ad-hoc code
// signature, so the grant has to be repeated after one.
//
//   wifi-ssid              print the SSID; if permission is undecided, ask
//                          and wait up to 60 s for the answer
//   wifi-ssid --no-prompt  print the SSID only if permission is already granted
//   wifi-ssid --debug      also print what CoreLocation and CoreWLAN report
//
// Exit status: 0 printed; 1 no Wi-Fi interface or not associated;
//              2 permission not granted (reason on stderr).
import CoreLocation
import CoreWLAN
import Foundation

let args = CommandLine.arguments.dropFirst()
let noPrompt = args.contains("--no-prompt")
let debug = args.contains("--debug")

func log(_ message: String) {
    if debug { fputs("wifi-ssid: " + message + "\n", stderr) }
}

// CoreLocation registers this process with locationd asynchronously and
// reports the result through this callback. CoreWLAN only hands out the SSID
// to a registered, authorized client, so the SSID is read after the callback,
// never straight after creating the manager.
final class AuthWatcher: NSObject, CLLocationManagerDelegate {
    var status: CLAuthorizationStatus?
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        log("authorization callback: status \(manager.authorizationStatus.rawValue), accuracy \(manager.accuracyAuthorization.rawValue)")
        CFRunLoopStop(CFRunLoopGetMain())
    }
}

/// Runs the main run loop until the watcher reports a status that passes `until`, or `seconds` elapse.
func wait(_ watcher: AuthWatcher, seconds: Double, until done: (CLAuthorizationStatus?) -> Bool) {
    let deadline = Date().addingTimeInterval(seconds)
    while !done(watcher.status) {
        let left = deadline.timeIntervalSinceNow
        if left <= 0 { break }
        _ = CFRunLoopRunInMode(.defaultMode, left, false)
    }
}

func printSSID() -> Int32 {
    guard let interface = CWWiFiClient.shared().interface() else {
        fputs("wifi-ssid: no Wi-Fi interface\n", stderr)
        return 1
    }
    log("interface \(interface.interfaceName ?? "?"), power \(interface.powerOn()), bssid \(interface.bssid() ?? "nil"), ssidData \(interface.ssidData().map { "\($0.count) bytes" } ?? "nil"), channel \(interface.wlanChannel()?.channelNumber ?? 0), rssi \(interface.rssiValue())")
    guard let ssid = interface.ssid(), !ssid.isEmpty else {
        log("ssid is nil: not associated, or the SSID is still withheld")
        return 1  // not associated
    }
    print(ssid)
    return 0
}

let manager = CLLocationManager()
let watcher = AuthWatcher()
manager.delegate = watcher
wait(watcher, seconds: 5) { $0 != nil }  // registration with locationd
log("initial status \(manager.authorizationStatus.rawValue) (0 undecided, 2 denied, 3 authorized)")

if manager.authorizationStatus == .notDetermined && !noPrompt {
    manager.requestWhenInUseAuthorization()
    wait(watcher, seconds: 60) { $0 != nil && $0 != .notDetermined }  // the dialog
}

switch manager.authorizationStatus {
case .authorizedAlways:
    exit(printSSID())
case .notDetermined:
    fputs("wifi-ssid: Location Services permission not granted yet; run: open ~/.config/sketchybar/wifi-ssid/wifi-ssid.app\n", stderr)
    exit(2)
default:
    fputs("wifi-ssid: Location Services permission denied; allow wifi-ssid in System Settings > Privacy & Security > Location Services\n", stderr)
    exit(2)
}
