//
//  Modified version of DirectoryHTTPHandler.swift
//  FlyingFox
//
//  Created by Huw Rowlands on 20/03/2022.
//  Copyright © 2022 Simon Whitty. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/swhitty/FlyingFox
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import FlyingFox

let notFound = "Not found".data(using: .utf8)!

public struct MyDirectoryHTTPHandler: HTTPHandler {

    private(set) var root: URL?
    let serverPath: String

    public init(root: URL, serverPath: String = "/") {
        self.root = root
        self.serverPath = serverPath
    }

    public init(bundle: Bundle, subPath: String = "", serverPath: String) {
        self.root = bundle.resourceURL?.appendingPathComponent(subPath)
        self.serverPath = serverPath
    }

    public func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        print("Handle request", request.path)
        let notFoundResponse = HTTPResponse(statusCode: .notFound, body: notFound)
        guard
            let filePath = makeFileURL(for: request.path) else {
            return notFoundResponse
        }
        return respondFor(path: filePath) ?? respondFor(path: filePath.appendingPathComponent("index.html")) ?? notFoundResponse

    }

    func respondFor(path filePath: URL) -> HTTPResponse? {
        guard let data = try? Data(contentsOf: filePath) else {
            return nil
        }

        return HTTPResponse(
            statusCode: .ok,
            headers: [.contentType: makeContentType(for: filePath.absoluteString)],
            body: data
        )

    }

    func makeFileURL(for requestPath: String) -> URL? {
        let compsA = serverPath
            .split(separator: "/", omittingEmptySubsequences: true)
            .joined(separator: "/")
        let compsB = requestPath
            .split(separator: "/", omittingEmptySubsequences: true)
            .joined(separator: "/")

        guard compsB.hasPrefix(compsA) else { return nil }
        let subPath = String(compsB.dropFirst(compsA.count))
        return root?.appendingPathComponent(subPath)
    }
}

func makeContentType(for filename: String) -> String {
    // TODO: UTTypeCreatePreferredIdentifierForTag / UTTypeCopyPreferredTagWithClass
    let pathExtension = (filename.lowercased() as NSString).pathExtension
    switch pathExtension {
    case "json":
        return "application/json"
    case "html", "htm":
        return "text/html"
    case "css":
        return "text/css"
    case "js", "javascript":
        return "application/javascript"
    case "png":
        return "image/png"
    case "jpeg", "jpg":
        return "image/jpeg"
    case "pdf":
        return "application/pdf"
    case "svg":
        return "image/svg+xml"
    case "ico":
        return "image/x-icon"
    case "wasm":
        return "application/wasm"
    case "webp":
        return "image/webp"
    case "jp2":
        return "image/jp2"
    default:
        return "application/octet-stream"
    }
}
