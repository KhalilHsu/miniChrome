import Foundation
import Darwin

enum BridgeQueue {
    private static let queueFileName = "pending-urls.txt"

    static func drain() throws -> [String] {
        let queueURL = try queueFileURL()
        try ensureParentDirectoryExists(for: queueURL)

        if !FileManager.default.fileExists(atPath: queueURL.path) {
            FileManager.default.createFile(atPath: queueURL.path, contents: nil)
        }

        let handle = try FileHandle(forUpdating: queueURL)
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

    private static func queueFileURL() throws -> URL {
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
