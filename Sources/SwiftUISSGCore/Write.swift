import SwiftUI
import Foundation

extension EnvironmentValues {
    @Entry var cleanup = true
    @Entry public var onWrite: ((String) -> Void)? = nil
}

public struct Write: View {
    @Environment(\.outputURL) private var outputURL: URL
    @Environment(\.cleanup) private var cleanup
    @Environment(\.onWrite) private var onWrite
    @Environment(\.baseOutputURL) private var baseOutputURL: URL

    public init(to: String, _ contents: String) {
        self.payload = .init(contents: contents.data(using: .utf8)!, to: to)
    }
    
    public init(to: String, _ contents: Data) {
        self.payload = .init(contents: contents, to: to)
    }

    struct Payload: Equatable {
        var contents: Data
        var to: String
    }

    var payload: Payload


    var result: URL {
        outputURL.appendingPathComponent(payload.to)
    }


    public var body: some View {
        LabeledContent("Write") {
            Text("\(payload.to)")
        }
        .changeEffect(trigger: payload)
        .sideEffect(trigger: payload) {
            let dir = result.deletingLastPathComponent()
            let fm = FileManager.default
            if !fm.fileExists(atPath: dir.path()) {
                try! fm.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            if let w = onWrite {
                let base = baseOutputURL
                let url = result
                assert(url.absoluteString.hasPrefix(base.absoluteString))
                let remainder = String(url.absoluteString.dropFirst(base.absoluteString.count))
                w(remainder)
            }
            log("Write \(payload.to)")
            try! payload.contents.write(to: result)
        }
        .onDisappear {
            do {
                guard cleanup else { return }
                let fm = FileManager.default
                try fm.removeItem(atPath: result.path())
                log("Remove \(payload.to)")
            } catch {
                log("\(error)")
            }
        }
    }
}

