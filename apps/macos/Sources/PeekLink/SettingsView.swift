import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("chromeExtensionId") private var chromeExtensionId: String = ""
    @AppStorage("extensionSourcePath") private var extensionSourcePath: String = ""
    @AppStorage("lastDeliveryStatus") private var lastDeliveryStatus: String = L10n.tr("No links delivered yet.")
    @AppStorage("lastDeliveryURL") private var lastDeliveryURL: String = ""
    @AppStorage("lastDeliveryDate") private var lastDeliveryDate: String = ""
    @AppStorage("appLanguage") private var appLanguage: String = "system"
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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.tr("Setup"))
                    .font(.title3.weight(.semibold))

                Text(L10n.tr("Finish these once, then external links can open in Mini Chrome."))
                    .foregroundColor(.secondary)
            }

            SettingsBlock(title: L10n.tr("Language")) {
                Picker(L10n.tr("App Language"), selection: $appLanguage) {
                    Text(L10n.tr("Follow System")).tag("system")
                    Text("English").tag("en")
                    Text("简体中文").tag("zh-Hans")
                }
                .pickerStyle(.segmented)
            }

            Divider()

            SettingsBlock(title: L10n.tr("Link Opening")) {
                SetupChecklistRow(
                    title: L10n.tr("PeekLink is default browser"),
                    detail: defaultBrowserStatusText,
                    isComplete: isDefaultBrowser,
                    actionTitle: L10n.tr("Open Settings"),
                    action: Self.openDefaultBrowserSettings
                )

                SetupChecklistRow(
                    title: L10n.tr("Test link opens through PeekLink"),
                    detail: L10n.tr("Send a test URL through the same queue used by external links."),
                    isComplete: isLastDeliveryQueued,
                    actionTitle: L10n.tr("Open Test Link"),
                    action: openTestLink
                )

                DeliveryStatusView(
                    status: lastDeliveryStatus,
                    url: lastDeliveryURL,
                    date: lastDeliveryDate
                )
            }

            Divider()

            SettingsBlock(title: L10n.tr("Chrome Connection")) {
                SetupStepRow(
                    number: 1,
                    title: L10n.tr("Open Chrome Extensions"),
                    detail: L10n.tr("Turn on Developer mode in the top-right corner."),
                    primaryTitle: L10n.tr("Open Extensions"),
                    primaryAction: Self.openChromeExtensions
                )

                SetupStepRow(
                    number: 2,
                    title: L10n.tr("Load the PeekLink extension folder"),
                    detail: extensionInstallDetail,
                    primaryTitle: L10n.tr("Reveal Folder"),
                    primaryAction: revealExtensionFolder
                )

                SetupStepRow(
                    number: 3,
                    title: L10n.tr("Copy the extension ID"),
                    detail: L10n.tr("After Chrome loads PeekLink Companion, copy the 32-letter ID shown on that extension card."),
                    primaryTitle: nil,
                    primaryAction: nil
                )

                Text(L10n.tr("Paste Extension ID"))
                    .font(.subheadline.weight(.medium))

                TextField(L10n.tr("Paste the 32-character ID from chrome://extensions"), text: $chromeExtensionId)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: chromeExtensionId) { newValue in
                        normalizeAndInstallExtensionId(newValue)
                    }

                Text(extensionIdHelpText)
                    .font(.caption)
                    .foregroundColor(isExtensionIdValid || !hasExtensionId ? .secondary : .red)

                SetupChecklistRow(
                    title: L10n.tr("Native bridge ready"),
                    detail: bridgeStatusText,
                    isComplete: isBridgeReady,
                    actionTitle: L10n.tr("Refresh"),
                    action: refreshBridge
                )
            }

            Divider()

            SettingsBlock(title: L10n.tr("Advanced")) {
                HStack(spacing: 8) {
                    Button(L10n.tr("Reveal Extension Folder"), action: revealExtensionFolder)
                        .disabled(extensionSourcePath.isEmpty)
                    Button(L10n.tr("Copy Manifest Path"), action: copyManifestPath)
                }

                Text(advancedStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 0)
            }
        }
        .padding(22)
        .frame(width: 640, height: 760)
        .onAppear(perform: refreshSetupState)
    }

    private var isLastDeliveryQueued: Bool {
        lastDeliveryStatus == L10n.tr("Queued for Chrome native bridge.")
            || lastDeliveryStatus == L10n.tr("Queued, but Chrome bridge is not configured.")
            || lastDeliveryStatus == "Queued for Chrome native bridge."
            || lastDeliveryStatus == "Queued, but Chrome bridge is not configured."
    }

    private var bridgeStatusText: String {
        if !isExtensionIdValid {
            return L10n.tr("Waiting for a valid extension ID.")
        }

        return isBridgeReady ? L10n.tr("Native messaging manifest is installed.") : L10n.tr("Manifest needs to be refreshed.")
    }

    private var defaultBrowserStatusText: String {
        isDefaultBrowser ? L10n.tr("External http and https links route through PeekLink.") : L10n.tr("Set PeekLink as the default web browser in macOS.")
    }

    private var extensionIdHelpText: String {
        if !hasExtensionId {
            return L10n.tr("This is the ID from the PeekLink Companion card in chrome://extensions.")
        }

        if isExtensionIdValid {
            return L10n.tr("Saved. PeekLink will install the native messaging bridge for this extension.")
        }

        return L10n.tr("This does not match Chrome's extension ID format.")
    }

    private var extensionInstallDetail: String {
        if extensionSourcePath.isEmpty {
            return L10n.tr("Click Load unpacked in Chrome, then select the PeekLink ChromeExtension folder.")
        }

        return L10n.tr("Click Reveal Folder, then in Chrome click Load unpacked and choose the revealed ChromeExtension folder.")
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

    private func openTestLink() {
        NotificationCenter.default.post(name: Notification.Name("OpenTestLink"), object: nil)
        refreshSetupState()
    }

    private var advancedStatusText: String {
        let extensionPath = extensionSourcePath.isEmpty ? L10n.tr("Extension folder path was not saved by install.sh.") : extensionSourcePath
        return L10n.format("Extension folder: %@\nNative manifest: %@", extensionPath, NativeMessagingManifest.manifestPath())
    }

    private func revealExtensionFolder() {
        guard !extensionSourcePath.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: extensionSourcePath)])
    }

    private func copyManifestPath() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(NativeMessagingManifest.manifestPath(), forType: .string)
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

private struct SettingsBlock<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content
        }
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

private struct SetupStepRow: View {
    let number: Int
    let title: String
    let detail: String
    let primaryTitle: String?
    let primaryAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.accentColor))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if let primaryTitle, let primaryAction {
                Button(primaryTitle, action: primaryAction)
                    .controlSize(.small)
            }
        }
    }
}

private struct DeliveryStatusView: View {
    let status: String
    let url: String
    let date: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(status)
                .font(.caption.weight(.medium))
            if !date.isEmpty {
                Text("\(date) - \(url)")
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
}
