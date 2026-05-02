import Foundation
import Darwin

struct NativeBridgeMessage: Codable {
    let action: String
    let url: String?
    let source: String?
}

let host = PeekLinkNativeHost()
host.run()

final class PeekLinkNativeHost {
    private let stdinHandle = FileHandle.standardInput
    private let stdoutHandle = FileHandle.standardOutput
    private let queue = DispatchQueue(label: "com.peeklink.host.queue")
    private let encoder = JSONEncoder()
    private var timer: DispatchSourceTimer?
    private var isRunning = true

    func run() {
        startStdinReader()
        startQueuePolling()

        while isRunning && RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.25)) {}
    }

    private func startQueuePolling() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(250))
        timer.setEventHandler { [weak self] in
            self?.drainQueue()
        }
        timer.resume()
        self.timer = timer
    }

    private func drainQueue() {
        do {
            let urls = try BridgeQueue.drain()
            for url in urls {
                try send(NativeBridgeMessage(action: "openMiniWindow", url: url, source: "bridge"))
            }
        } catch {
            fputs("[PeekLinkHost] drain error: \(error)\n", stderr)
        }
    }

    private func startStdinReader() {
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            while self.isRunning {
                guard let data = self.readNativeMessage() else {
                    self.isRunning = false
                    break
                }

                if let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let action = message["action"] as? String,
                   action == "ping" {
                    let response = NativeBridgeMessage(action: "pong", url: nil, source: "bridge")
                    try? self.send(response)
                }
            }
        }

        DispatchQueue.global(qos: .utility).async(execute: item)
    }

    private func readNativeMessage() -> Data? {
        let lengthData = stdinHandle.readData(ofLength: 4)
        guard lengthData.count == 4 else { return nil }

        let bytes = [UInt8](lengthData)
        let length = UInt32(bytes[0])
            | (UInt32(bytes[1]) << 8)
            | (UInt32(bytes[2]) << 16)
            | (UInt32(bytes[3]) << 24)

        guard length > 0 else { return nil }
        let messageData = stdinHandle.readData(ofLength: Int(length))
        return messageData.count == Int(length) ? messageData : nil
    }

    private func send(_ message: NativeBridgeMessage) throws {
        let data = try encoder.encode(message)
        var length = UInt32(data.count).littleEndian
        let lengthData = withUnsafeBytes(of: &length) { Data($0) }
        stdoutHandle.write(lengthData)
        stdoutHandle.write(data)
    }
}
