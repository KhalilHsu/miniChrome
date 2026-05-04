import SwiftUI
import AppKit

@main
struct PeekLinkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) var openWindow

    init() {
        NSApplication.shared.applicationIconImage = BrandAssets.appIcon()
    }

    var body: some Scene {
        Window(L10n.tr("Settings"), id: "settings") {
            SettingsView()
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenSettings"))) { _ in
                    openWindow(id: "settings")
                }
        }

        MenuBarExtra("PeekLink", systemImage: "link") {
            Button(L10n.tr("Settings")) {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button(L10n.tr("Quit PeekLink")) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
