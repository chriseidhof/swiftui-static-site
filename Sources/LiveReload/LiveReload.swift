import FlyingFox
import Foundation

public let liveReloadSnippet = """
<script>document.write('<script src="http://'
    + (location.host || 'localhost').split(':')[0]
    + ':35729/livereload.js?snipver=1"></'
    + 'script>')</script>
"""

public final class Reloads {
    var observers: [@Sendable (String) async throws -> ()] = []

    init() { }


    public func reload(path: String) {
        let theObservers = observers
        Task {
            try await withThrowingDiscardingTaskGroup { group in
                for o in theObservers {
                    group.addTask { try await o(path) }
                }
            }
        }
    }

    public nonisolated(unsafe) static let shared = Reloads() // todo
}

public func liveReload() async throws {
    let liveReload = HTTPServer(port: 35729)
    let reloads = Reloads()

    await liveReload.appendRoute("/livereload.js", to: FileHTTPHandler(named: "livereload.js", in: .module))
    //await liveReload.appendRoute("GET *") { request in
    //    print(request.path, request.method, request.query)
    //    return HTTPResponse(statusCode: .notFound)
    //}

    await liveReload.appendRoute("GET *", to: .webSocket(MyHandler()))

    try await liveReload.run()
}

final class MyHandler: WSMessageHandler {
    func makeMessages(for client: AsyncStream<WSMessage>) async throws -> AsyncStream<WSMessage> {
        AsyncStream { cont in
            Task {
                for try await msg in client {
                    if case .text(let string) = msg {
                        if let response = try handleLiveReloadMessage(msg: string) {
                            let text = String(data: response, encoding: .utf8)!
                            cont.yield(.text(text))
                        }
                    }
                }
                print("Done with for loop")
                cont.finish()
            }
            Task {
                Reloads.shared.observers.append { path in
                    cont.yield(.text("{\"command\":\"reload\",\"path\":\"\(path)\"}"))
                }
            }
        }
    }

}

struct LiveReloadMessage: Codable {
    var command: String
    var url: String?
}

struct ReloadCommand: Codable {
    var command: String = "reload"
    var path: String
}

struct HelloResponse: Codable {
    var command = "hello"
    var protocols = ["http://livereload.com/protocols/official-7"]
    var serverName: String = "test"
}

func handleLiveReloadMessage(msg: String) throws -> Data? {
    print(msg)
    let message = try JSONDecoder().decode(LiveReloadMessage.self, from: msg.data(using: .utf8)!)
    switch message.command {
    case "hello":
        return try JSONEncoder().encode(HelloResponse())
    case "info":
        return nil
    default:
        return nil
    }
}
