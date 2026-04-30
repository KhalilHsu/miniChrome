import Cocoa
import SwiftUI
import os.log

class AppDelegate: NSObject, NSApplicationDelegate {
    @AppStorage("chromeExtensionId") private var chromeExtensionId: String = ""
    @AppStorage("chromeAppName") private var chromeAppName: String = "Google Chrome"

    private let logger = Logger(subsystem: "com.peeklink.app", category: "URLHandler")
    private var pendingURLs: [String] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(flushPendingURLs),
            name: Notification.Name("FlushPendingURLs"),
            object: nil
        )
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else { return }
        forwardToChrome(urlString: urlString)
    }

    func forwardToChrome(urlString: String) {
        let extId = chromeExtensionId.trimmingCharacters(in: .whitespacesAndNewlines)

        if extId.isEmpty {
            pendingURLs.append(urlString)
            logger.warning("Extension ID not configured, URL queued: \(urlString)")
            showMissingExtensionIdAlert()
            return
        }

        if !isValidExtensionId(extId) {
            pendingURLs.append(urlString)
            logger.error("Invalid Extension ID format: \(extId), URL queued: \(urlString)")
            showInvalidExtensionIdAlert()
            return
        }

        launchChrome(with: urlString, extensionId: extId)
    }

    private func isValidExtensionId(_ id: String) -> Bool {
        return id.count == 32 && id.allSatisfy { $0.isLetter || $0.isNumber }
    }

    private func launchChrome(with urlString: String, extensionId extId: String) {
        var components = URLComponents(string: "chrome-extension://\(extId)/open.html")
        components?.queryItems = [URLQueryItem(name: "url", value: urlString)]

        guard let chromeUrl = components?.url?.absoluteString else {
            logger.error("Failed to construct chrome-extension URL for: \(urlString)")
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", chromeAppName, chromeUrl]

        do {
            try process.run()
            logger.info("Forwarded URL to Chrome: \(urlString)")
        } catch {
            logger.error("Failed to open Chrome: \(error.localizedDescription)")
            showChromeLaunchErrorAlert(error, url: urlString)
        }
    }

    @objc func flushPendingURLs() {
        guard !pendingURLs.isEmpty else { return }
        let urls = pendingURLs
        pendingURLs.removeAll()
        logger.info("Flushing \(urls.count) pending URL(s)")
        for url in urls {
            forwardToChrome(urlString: url)
        }
    }

    private func showMissingExtensionIdAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Extension ID Missing"
            alert.informativeText = "Please set your Chrome Extension ID in PeekLink Settings. The URL will be opened automatically once configured."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")

            NSApp.activate(ignoringOtherApps: true)
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NotificationCenter.default.post(name: Notification.Name("OpenSettings"), object: nil)
            }
        }
    }

    private func showInvalidExtensionIdAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Invalid Extension ID"
            alert.informativeText = "The configured Extension ID does not appear to be valid. A Chrome Extension ID should be a 32-character alphanumeric string. Please check your Settings."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")

            NSApp.activate(ignoringOtherApps: true)
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NotificationCenter.default.post(name: Notification.Name("OpenSettings"), object: nil)
            }
        }
    }

    private func showChromeLaunchErrorAlert(_ error: Error, url: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Failed to Open Chrome"
            alert.informativeText = """
            Could not open Chrome with the URL.
            Error: \(error.localizedDescription)

            You can copy the URL and open it manually.
            """
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Copy URL")
            alert.addButton(withTitle: "Dismiss")

            NSApp.activate(ignoringOtherApps: true)
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url, forType: .string)
            }
        }
    }
}
