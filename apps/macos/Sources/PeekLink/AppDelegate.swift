import Cocoa
import SwiftUI
import os.log

final class AppDelegate: NSObject, NSApplicationDelegate {
    @AppStorage("chromeExtensionId") private var chromeExtensionId: String = ""

    private let logger = Logger(subsystem: "com.peeklink.app", category: "URLHandler")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.applicationIconImage = BrandAssets.appIcon()

        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshNativeMessagingManifest),
            name: Notification.Name("RefreshNativeMessagingManifest"),
            object: nil
        )

        refreshNativeMessagingManifest()
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else { return }
        handleIncomingURL(urlString)
    }

    private func handleIncomingURL(_ urlString: String) {
        let extId = chromeExtensionId.trimmingCharacters(in: .whitespacesAndNewlines)
        if extId.isEmpty || !isValidExtensionId(extId) {
            logger.warning("Native messaging bridge not configured, URL queued: \(urlString)")
            showBridgeMissingAlert()
        }

        do {
            try BridgeQueue.append(urlString: urlString)
            logger.info("Queued URL for native bridge: \(urlString)")
        } catch {
            logger.error("Failed to queue URL: \(error.localizedDescription)")
            showQueueErrorAlert(error, url: urlString)
        }
    }

    @objc private func refreshNativeMessagingManifest() {
        let extId = chromeExtensionId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidExtensionId(extId) else { return }

        do {
            try NativeMessagingManifest.install(extensionId: extId)
            logger.info("Refreshed native messaging manifest for extension: \(extId)")
        } catch {
            logger.error("Failed to install native messaging manifest: \(error.localizedDescription)")
        }
    }

    private func isValidExtensionId(_ id: String) -> Bool {
        return id.count == 32 && id.allSatisfy { $0.isLetter || $0.isNumber }
    }

    private func showBridgeMissingAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "PeekLink Bridge Not Ready"
            alert.informativeText = "Set your Chrome Extension ID in PeekLink Settings so the native messaging bridge can be installed."
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

    private func showQueueErrorAlert(_ error: Error, url: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Failed to Queue URL"
            alert.informativeText = """
            Could not save the URL for delivery to Chrome.
            Error: \(error.localizedDescription)

            URL: \(url)
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
