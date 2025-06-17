import SwiftUI
import SwiftUISSG
import Foundation
import LiveReload
import Swim

public struct LiveReloadTemplate: Template {
    @NodeBuilder
    public func run(content: Node, environment: EnvironmentValues) -> Node {
        content
        Node.raw(liveReloadSnippet)
    }
}

extension Template where Self == LiveReloadTemplate {
    static public var liveReload: Self {
        .init()
    }
}


public struct GUIView<Site: Rule>: View {
    public init(site: Site, base: URL, out: URL? = nil, startServer: Bool = false) {
        self.site = site
        self.base = base
        self.out = out ?? base.appending(component: "_out")
        self.startServer = startServer
    }

    @ViewBuilder private var site: Site
    @State private var serverTask: Task<Void, Never>? = nil
    var base = URL.temporaryDirectory.appendingPathComponent("app")
    var out: URL
    var startServer: Bool = false
    public var body: some View {
        VStack(alignment: .leading) {
            VSplitView {
                ScrollView {
                    site
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .safeAreaPadding()
                        .staticSite(inputURL: base, outputURL: out)
                        .wrap(serverTask == nil ? .identity as any Template : .liveReload as any Template)
                        .environment(\.onWrite) {
                            Reloads.shared.reload(path: $0)
                        }
                }
                ConsoleView()
            }
            .toolbar {
                toolbarContent
            }
            .onAppear {
                if startServer && serverTask == nil {
                    startServerHelper()
                }
            }
        }
    }

    @ViewBuilder
    var toolbarContent: some View {
        Button("Directory") {
            NSWorkspace.shared.open(base)
        }
        Button {
            if serverTask == nil {
                startServerHelper()
            } else {
                serverTask = nil
            }
        } label: {
            let started = serverTask != nil
            Label(started ? "Stop Server" : "Start Server", systemImage: started ? "stopfill" : "play")
        }
        .labelStyle(.titleAndIcon)
        Button("Open Site") {
            NSWorkspace.shared.open(serverURL)
        }
    }

    func startServerHelper() {
        serverTask = Task {
            await withDiscardingTaskGroup { group in
                group.addTask {
                    try! await runServer(baseURL: out)
                }
                group.addTask {
                    try! await liveReload()
                }
            }
        }
    }
}

#Preview {
    GUIView(site: Text(""), base: URL.temporaryDirectory)
}
