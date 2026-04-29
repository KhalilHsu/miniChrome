import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    @AppStorage("chromeExtensionId") private var chromeExtensionId: String = ""
    @AppStorage("chromeAppName") private var chromeAppName: String = "Google Chrome"

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register URL handler for http and https
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else { return }
        forwardToChrome(urlString: urlString)
    }

    func forwardToChrome(urlString: String) {
        let extId = chromeExtensionId.trimmingCharacters(in: .whitespacesAndNewlines)
        if extId.isEmpty {
            // Prompt user to set extension ID
            let alert = NSAlert()
            alert.messageText = "Extension ID Missing"
            alert.informativeText = "Please set your Chrome Extension ID in PeekLink Settings."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")
            
            NSApp.activate(ignoringOtherApps: true)
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NotificationCenter.default.post(name: Notification.Name("OpenSettings"), object: nil)
            }
            return
        }

        var components = URLComponents(string: "chrome-extension://\(extId)/open.html")
        components?.queryItems = [URLQueryItem(name: "url", value: urlString)]
        
        guard let chromeUrl = components?.url?.absoluteString else { return }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", chromeAppName, chromeUrl]
        
        do {
            try process.run()
        } catch {
            print("Failed to open Chrome: \(error)")
        }
    }
}
