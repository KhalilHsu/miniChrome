import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("chromeExtensionId") private var chromeExtensionId: String = ""
    @AppStorage("lastDeliveryStatus") private var lastDeliveryStatus: String = "No links delivered yet."
    @AppStorage("lastDeliveryURL") private var lastDeliveryURL: String = ""
    @AppStorage("lastDeliveryDate") private var lastDeliveryDate: String = ""
    @State private var refreshToken = UUID()

    private var trimmedExtensionId: String {
        chromeExtensionId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasExtensionId: Bool {
        !trimmedExtensionId.isEmpty
    }

    private var isExtensionIdValid: Bool {
        Self.isValidExtensionId(trimmedExtensionId)
    }

    private var isDefaultBrowser: Bool {
        refreshToken.uuidString.isEmpty ? false : Self.isPeekLinkDefaultBrowser
    }

    private var isBridgeReady: Bool {
        isExtensionIdValid && NativeMessagingManifest.isInstalled(for: trimmedExtensionId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Setup")
                    .font(.title3.weight(.semibold))

                Text("Finish these once, then external links can open in Mini Chrome.")
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                SetupChecklistRow(
                    title: "Chrome extension loaded",
                    detail: "Load the local extension/chrome folder in Chrome.",
                    isComplete: hasExtensionId,
                    actionTitle: "Open Extensions",
                    action: Self.openChromeExtensions
                )

                SetupChecklistRow(
                    title: "Extension ID configured",
                    detail: extensionIdStatusText,
                    isComplete: isExtensionIdValid,
                    actionTitle: nil,
                    action: nil
                )

                SetupChecklistRow(
                    title: "Native bridge ready",
                    detail: bridgeStatusText,
                    isComplete: isBridgeReady,
                    actionTitle: "Refresh",
                    action: refreshBridge
                )

                SetupChecklistRow(
                    title: "PeekLink is default browser",
                    detail: defaultBrowserStatusText,
                    isComplete: isDefaultBrowser,
                    actionTitle: "Open Settings",
                    action: Self.openDefaultBrowserSettings
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Chrome Extension ID")
                    .font(.headline)

                TextField("Paste the 32-character ID from chrome://extensions", text: $chromeExtensionId)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: chromeExtensionId) { newValue in
                        normalizeAndInstallExtensionId(newValue)
                    }

                Text(extensionIdHelpText)
                    .font(.caption)
                    .foregroundColor(isExtensionIdValid || !hasExtensionId ? .secondary : .red)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Test")
                            .font(.headline)
                        Text("Send a test URL through the same queue used by external links.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Open Test Link") {
                        NotificationCenter.default.post(name: Notification.Name("OpenTestLink"), object: nil)
                        refreshSetupState()
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(lastDeliveryStatus)
                        .font(.caption.weight(.medium))
                    if !lastDeliveryDate.isEmpty {
                        Text("\(lastDeliveryDate) - \(lastDeliveryURL)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
            }

            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(width: 560, height: 610)
        .onAppear(perform: refreshSetupState)
    }

    private var extensionIdStatusText: String {
        if !hasExtensionId {
            return "Paste the ID Chrome shows for the unpacked PeekLink extension."
        }

        return isExtensionIdValid ? "ID format looks correct." : "The ID should be 32 lowercase letters from Chrome."
    }

    private var bridgeStatusText: String {
        if !isExtensionIdValid {
            return "Waiting for a valid extension ID."
        }

        return isBridgeReady ? "Native messaging manifest is installed." : "Manifest needs to be refreshed."
    }

    private var defaultBrowserStatusText: String {
        isDefaultBrowser ? "External http and https links route through PeekLink." : "Set PeekLink as the default web browser in macOS."
    }

    private var extensionIdHelpText: String {
        if !hasExtensionId {
            return "Open chrome://extensions, enable Developer mode, load extension/chrome, then copy its ID."
        }

        if isExtensionIdValid {
            return "Saved. PeekLink will install the native messaging bridge for this extension."
        }

        return "This does not match Chrome's extension ID format."
    }

    private func normalizeAndInstallExtensionId(_ newValue: String) {
        let normalized = newValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if normalized != newValue {
            chromeExtensionId = normalized
            return
        }

        if Self.isValidExtensionId(normalized) {
            NotificationCenter.default.post(name: Notification.Name("RefreshNativeMessagingManifest"), object: nil)
        }

        refreshSetupState()
    }

    private func refreshBridge() {
        guard isExtensionIdValid else { return }
        NotificationCenter.default.post(name: Notification.Name("RefreshNativeMessagingManifest"), object: nil)
        refreshSetupState()
    }

    private func refreshSetupState() {
        refreshToken = UUID()
    }

    private static func isValidExtensionId(_ id: String) -> Bool {
        id.count == 32 && id.allSatisfy { $0 >= "a" && $0 <= "z" }
    }

    private static var isPeekLinkDefaultBrowser: Bool {
        guard let httpURL = URL(string: "http://peeklink.local"),
              let httpsURL = URL(string: "https://peeklink.local") else {
            return false
        }

        let httpAppURL = NSWorkspace.shared.urlForApplication(toOpen: httpURL)
        let httpsAppURL = NSWorkspace.shared.urlForApplication(toOpen: httpsURL)
        let bundleURL = Bundle.main.bundleURL.standardizedFileURL

        return httpAppURL?.standardizedFileURL == bundleURL
            && httpsAppURL?.standardizedFileURL == bundleURL
    }

    private static func openChromeExtensions() {
        guard let url = URL(string: "chrome://extensions") else { return }

        if let chromeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome") {
            NSWorkspace.shared.open([url], withApplicationAt: chromeURL, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    private static func openDefaultBrowserSettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.Desktop-Settings.extension",
            "x-apple.systempreferences:com.apple.preference.general"
        ]

        for urlString in urls {
            if let url = URL(string: urlString), NSWorkspace.shared.open(url) {
                return
            }
        }

        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/System Settings.app"), configuration: NSWorkspace.OpenConfiguration())
    }
}

private struct SetupChecklistRow: View {
    let title: String
    let detail: String
    let isComplete: Bool
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? .green : .secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .controlSize(.small)
            }
        }
    }
}
