import SwiftUI

struct SettingsView: View {
    @AppStorage("chromeExtensionId") private var chromeExtensionId: String = ""
    @AppStorage("chromeAppName") private var chromeAppName: String = "Google Chrome"

    private var isExtensionIdValid: Bool {
        let id = chromeExtensionId.trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty || (id.count == 32 && id.allSatisfy { $0.isLetter || $0.isNumber })
    }

    var body: some View {
        Form {
            Section(header: Text("Chrome Extension Bridge")) {
                TextField("Extension ID", text: $chromeExtensionId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                    .onChange(of: chromeExtensionId) { newValue in
                        let id = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if id.count == 32 && id.allSatisfy({ $0.isLetter || $0.isNumber }) {
                            NotificationCenter.default.post(name: Notification.Name("FlushPendingURLs"), object: nil)
                        }
                    }

                if !isExtensionIdValid {
                    Text("Extension ID should be a 32-character alphanumeric string.")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text("Paste the ID of your unpacked PeekLink Chrome extension here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                TextField("Chrome App / Path", text: $chromeAppName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                    .padding(.top, 10)

                Text("E.g., 'Google Chrome', 'Google Chrome Canary', or absolute path.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(width: 400, height: 250)
    }
}
