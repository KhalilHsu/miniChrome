import Foundation
import Darwin

enum BridgeQueue {
    private static let queueFileName = "pending-urls.txt"

    static func append(urlString: String) throws {
        let queueURL = try queueFileURL()
        try ensureParentDirectoryExists(for: queueURL)

        let data = (urlString + "\n").data(using: .utf8) ?? Data()
        let fileURL = queueURL
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }

        let handle = try FileHandle(forUpdating: fileURL)
        defer { handle.closeFile() }

        try lock(handle.fileDescriptor)
        defer { unlock(handle.fileDescriptor) }

        handle.seekToEndOfFile()
        handle.write(data)
    }

    static func drain() throws -> [String] {
        let queueURL = try queueFileURL()
        try ensureParentDirectoryExists(for: queueURL)

        let fileURL = queueURL
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }

        let handle = try FileHandle(forUpdating: fileURL)
        defer { handle.closeFile() }

        try lock(handle.fileDescriptor)
        defer { unlock(handle.fileDescriptor) }

        let data = handle.readDataToEndOfFile()
        handle.truncateFile(atOffset: 0)

        let contents = String(data: data, encoding: .utf8) ?? ""
        return contents
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    static func queueFileURL() throws -> URL {
        let base = try applicationSupportDirectory()
        return base.appendingPathComponent(queueFileName, isDirectory: false)
    }

    private static func applicationSupportDirectory() throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appDir = base.appendingPathComponent("PeekLink", isDirectory: true)
        try fm.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
        return appDir
    }

    private static func ensureParentDirectoryExists(for url: URL) throws {
        let parent = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true, attributes: nil)
    }

    private static func lock(_ fd: Int32) throws {
        if flock(fd, LOCK_EX) != 0 {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Unable to lock bridge queue file"])
        }
    }

    private static func unlock(_ fd: Int32) {
        _ = flock(fd, LOCK_UN)
    }
}

enum NativeMessagingManifest {
    private static let manifestName = "com.peeklink.bridge.json"
    private static let hostName = "com.peeklink.bridge"

    static func install(extensionId: String) throws {
        let manifest = Manifest(
            name: hostName,
            description: "PeekLink native messaging bridge",
            path: hostBinaryPath().path,
            type: "stdio",
            allowedOrigins: ["chrome-extension://\(extensionId)/"]
        )

        let data = try JSONEncoder().encode(manifest)
        let url = manifestURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        try data.write(to: url, options: .atomic)
    }

    static func isInstalled(for extensionId: String) -> Bool {
        guard let data = try? Data(contentsOf: manifestURL()),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else {
            return false
        }

        return manifest.name == hostName
            && manifest.path == hostBinaryPath().path
            && manifest.allowedOrigins.contains("chrome-extension://\(extensionId)/")
    }

    static func manifestPath() -> String {
        manifestURL().path
    }

    private static func manifestURL() -> URL {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        let chromeDir = base
            .appendingPathComponent("Google", isDirectory: true)
            .appendingPathComponent("Chrome", isDirectory: true)
            .appendingPathComponent("NativeMessagingHosts", isDirectory: true)
        return chromeDir.appendingPathComponent(manifestName, isDirectory: false)
    }

    private static func hostBinaryPath() -> URL {
        Bundle.main.bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("MacOS", isDirectory: true)
            .appendingPathComponent("PeekLinkHost", isDirectory: false)
    }

    private struct Manifest: Codable {
        let name: String
        let description: String
        let path: String
        let type: String
        let allowedOrigins: [String]

        enum CodingKeys: String, CodingKey {
            case name
            case description
            case path
            case type
            case allowedOrigins = "allowed_origins"
        }
    }
}
