import SwiftUI

@main
struct PeekLinkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) var openWindow

    var body: some Scene {
        Window("Settings", id: "settings") {
            SettingsView()
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenSettings"))) { _ in
                    openWindow(id: "settings")
                }
        }

        MenuBarExtra("PeekLink", systemImage: "link") {
            Button("Settings") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Quit PeekLink") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
