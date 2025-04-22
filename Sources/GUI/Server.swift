import FlyingFox
import Foundation

let serverURL: URL = .init(string: "http://localhost:8090")!
func runServer(baseURL: URL) async throws {
    let server = HTTPServer(port: 8090)
    await server.appendRoute("GET *", to: MyDirectoryHTTPHandler(root: baseURL))
    try await server.run()
}
