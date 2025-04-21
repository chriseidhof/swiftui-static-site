import SwiftUI
import SwiftUISSG
import Example
import Foundation

struct ContentView: View {
    @State private var didAppear = false
    @State private var serverTask: Task<Void, Never>? = nil
    let base = URL.temporaryDirectory.appendingPathComponent("app")
    var body: some View {
        let out = base.appendingPathComponent("_out")
        VStack {
            if didAppear {
                Button("Directory") {
                    NSWorkspace.shared.open(base)
                }
                Button(serverTask == nil ? "Start Server" : "Stop Server") {
                    if serverTask == nil {
                        serverTask = Task {
                            try! await runServer(baseURL: out)
                        }
                    } else {
                        serverTask = nil
                    }
                }
                Button("Open Site") {
                    NSWorkspace.shared.open(serverURL)
                }
                Example()
                    .staticSite(inputURL: base, outputURL: out)
            } else {
                ProgressView()
            }
        }.onAppear {
            try! setupExample(at: base)
            didAppear = true
        }
    }
}
