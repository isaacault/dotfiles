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
// If System Settings > Privacy & Security > Location Services then lists
// wifi-ssid switched off, switch it on. A rebuild changes the ad-hoc code
// signature, so the grant has to be repeated after one.
//
//   wifi-ssid              print the SSID; if permission is undecided, ask
//                          and wait up to 60 s for the answer
//   wifi-ssid --no-prompt  print the SSID only if permission is already granted
//
// Exit status: 0 printed; 1 no Wi-Fi interface or not associated;
//              2 permission not granted (reason on stderr).
import CoreLocation
import CoreWLAN
import Foundation

final class AuthWatcher: NSObject, CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Also called once right after the delegate is set, with the current status.
        if manager.authorizationStatus != .notDetermined {
            CFRunLoopStop(CFRunLoopGetMain())
        }
    }
}

func printSSID() -> Int32 {
    guard let interface = CWWiFiClient.shared().interface() else {
        fputs("wifi-ssid: no Wi-Fi interface\n", stderr)
        return 1
    }
    guard let ssid = interface.ssid(), !ssid.isEmpty else {
        return 1  // not associated
    }
    print(ssid)
    return 0
}

let noPrompt = CommandLine.arguments.dropFirst().contains("--no-prompt")
let manager = CLLocationManager()
let watcher = AuthWatcher()
manager.delegate = watcher

if manager.authorizationStatus == .notDetermined && !noPrompt {
    manager.requestWhenInUseAuthorization()
    _ = CFRunLoopRunInMode(.defaultMode, 60, false)  // returns early once the user decides
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
