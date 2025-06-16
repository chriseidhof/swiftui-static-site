import SwiftUI
import SwiftUISSG
import Foundation
import LiveReload
import Swim

public struct LiveReloadTemplate: Template {
    @NodeBuilder
    public func run(content: Node) -> Node {
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
    public init(site: Site, base: URL, out: URL? = nil) {
        self.site = site
        self.base = base
        self.out = out ?? base.appending(component: "_out")
    }

    @ViewBuilder private var site: Site
    @State private var serverTask: Task<Void, Never>? = nil
    var base = URL.temporaryDirectory.appendingPathComponent("app")
    var out: URL
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
        }
    }

    @ViewBuilder
    var toolbarContent: some View {
        Button("Directory") {
            NSWorkspace.shared.open(base)
        }
        Button(serverTask == nil ? "Start Server" : "Stop Server") {
            if serverTask == nil {
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
            } else {
                serverTask = nil
            }
        }
        Button("Open Site") {
            NSWorkspace.shared.open(serverURL)
        }
    }
}
