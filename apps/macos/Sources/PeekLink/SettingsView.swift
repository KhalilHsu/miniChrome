import SwiftUI

struct SettingsView: View {
    @AppStorage("chromeExtensionId") private var chromeExtensionId: String = ""
    @AppStorage("chromeAppName") private var chromeAppName: String = "Google Chrome"

    var body: some View {
        Form {
            Section(header: Text("Chrome Extension Bridge")) {
                TextField("Extension ID", text: $chromeExtensionId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                
                Text("Paste the ID of your unpacked PeekLink Chrome extension here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
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
        .frame(width: 400, height: 230)
    }
}
