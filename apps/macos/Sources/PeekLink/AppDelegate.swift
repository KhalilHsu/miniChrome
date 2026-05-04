import Cocoa
import SwiftUI
import os.log

final class AppDelegate: NSObject, NSApplicationDelegate {
    @AppStorage("chromeExtensionId") private var chromeExtensionId: String = ""
    @AppStorage("lastDeliveryStatus") private var lastDeliveryStatus: String = L10n.tr("No links delivered yet.")
    @AppStorage("lastDeliveryURL") private var lastDeliveryURL: String = ""
    @AppStorage("lastDeliveryDate") private var lastDeliveryDate: String = ""

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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openTestLink),
            name: Notification.Name("OpenTestLink"),
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
            recordDeliveryStatus(L10n.tr("Queued, but Chrome bridge is not configured."), url: urlString)
            showBridgeMissingAlert()
        }

        do {
            try BridgeQueue.append(urlString: urlString)
            logger.info("Queued URL for native bridge: \(urlString)")
            if isValidExtensionId(extId) {
                recordDeliveryStatus(L10n.tr("Queued for Chrome native bridge."), url: urlString)
            }
        } catch {
            logger.error("Failed to queue URL: \(error.localizedDescription)")
            recordDeliveryStatus(L10n.format("Failed to queue URL: %@", error.localizedDescription), url: urlString)
            showQueueErrorAlert(error, url: urlString)
        }
    }

    @objc private func openTestLink() {
        handleIncomingURL("https://example.com/?peeklink-test=1")
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

    private func recordDeliveryStatus(_ status: String, url: String) {
        lastDeliveryStatus = status
        lastDeliveryURL = url
        lastDeliveryDate = Self.statusDateFormatter.string(from: Date())
    }

    private static let statusDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    private func showBridgeMissingAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = L10n.tr("PeekLink Bridge Not Ready")
            alert.informativeText = L10n.tr("Set your Chrome Extension ID in PeekLink Settings so the native messaging bridge can be installed.")
            alert.alertStyle = .warning
            alert.addButton(withTitle: L10n.tr("Open Settings"))
            alert.addButton(withTitle: L10n.tr("Cancel"))

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
            alert.messageText = L10n.tr("Failed to Queue URL")
            alert.informativeText = L10n.format("Could not save the URL for delivery to Chrome.\nError: %@\n\nURL: %@", error.localizedDescription, url)
            alert.alertStyle = .critical
            alert.addButton(withTitle: L10n.tr("Copy URL"))
            alert.addButton(withTitle: L10n.tr("Dismiss"))

            NSApp.activate(ignoringOtherApps: true)
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url, forType: .string)
            }
        }
    }
}
