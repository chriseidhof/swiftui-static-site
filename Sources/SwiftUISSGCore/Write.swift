import SwiftUI
import Foundation

extension EnvironmentValues {
    @Entry var cleanup = true
}

public struct Write: View {
    @Environment(\.outputURL) private var outputURL: URL
    @Environment(\.cleanup) private var cleanup

    public init(_ contents: String, to: String) {
        self.payload = .init(contents: contents.data(using: .utf8)!, to: to)
    }
    
    public init(_ contents: Data, to: String) {
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
        .onChange(of: payload, initial: true) {
                let dir = result.deletingLastPathComponent()
                let fm = FileManager.default
                if !fm.fileExists(atPath: dir.path()) {
                    try! fm.createDirectory(at: dir, withIntermediateDirectories: true)
                }
                log("Write \(result)")
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
