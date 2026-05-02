import SwiftUI

struct SettingsView: View {
    @AppStorage("chromeExtensionId") private var chromeExtensionId: String = ""

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
                            NotificationCenter.default.post(name: Notification.Name("RefreshNativeMessagingManifest"), object: nil)
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

                Text("This ID is used to install the native messaging bridge for your unpacked Chrome extension.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 10)
            }
        }
        .padding(20)
        .frame(width: 420, height: 220)
    }
}
