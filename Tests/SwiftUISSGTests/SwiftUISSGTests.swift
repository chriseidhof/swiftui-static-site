import Testing
import Foundation
import Example
import SwiftUI
@testable import SwiftUISSGCore

enum Tree: Hashable {
    case file(Data)
    case directory([String: Tree])
}

extension Tree: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self = .file(value.data(using: .utf8)!)
    }
}

extension Tree: CustomStringConvertible {
    func pretty(indent: String = "") -> String {
        switch self {
        case .directory(let items):
            return items.map { (key, value) in
                "\(indent)\(key):\n" +
                "\(indent)\(value.pretty(indent: indent + "  "))"
            }.joined(separator: "\n")
        case .file(let d):
            return "\"\(String(decoding: d, as: UTF8.self))\""
        }
    }

    var description: String {
        pretty()
    }
}

extension Tree {
    func write(to url: URL) throws {
        switch self {
        case .file(let f):
            try f.write(to: url)
        case .directory(let d):
            let fm = FileManager.default
            if !fm.fileExists(atPath: url.path()) {
                try fm.createDirectory(at: url, withIntermediateDirectories: true)
            }
            for (key, value) in d {
                try value.write(to: url.appendingPathComponent(key))
            }
        }
    }

    static func read(from: URL) throws -> Tree {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: from.path(), isDirectory: &isDir) else {
            fatalError()
        }
        if isDir.boolValue {
            // read dir
            let contents = try fm.contentsOfDirectory(atPath: from.path())
                .filter { !$0.hasPrefix(".") }
            return .directory(.init(uniqueKeysWithValues: try contents.map {
                try ($0, .read(from: from.appendingPathComponent($0)))
            }))

        } else {
            return try .file(Data(contentsOf: from))
        }
    }
}

extension Tree {
    func flattenHelper(into: inout [String: Data], prefix: [String]) {
        switch self {
        case .file(let data):
            into[prefix.joined(separator: "/")] = data
        case .directory(let dictionary):
            for (key, value) in dictionary {
                value.flattenHelper(into: &into, prefix: prefix + [key])
            }
        }
    }

    func flatten() -> [String: Data] {
        var result: [String: Data] = [:]
        flattenHelper(into: &result, prefix: [])
        return result
    }

    func diff(_ other: Tree) -> String {
        let src = flatten().sorted { $0.key < $1.key }
        let otherFlat = other.flatten()
        let dst = otherFlat.sorted { $0.key < $1.key }
        let keysDiff = dst.map(\.key).difference(from: src.map(\.key))
        guard keysDiff.isEmpty else {
            return (keysDiff.removals.map { "Removed: \($0)" } + keysDiff.insertions.map { "Added: \($0)" }).joined(separator: "\n")
        }
        let changedKeys = zip(src, dst).filter {
            $0.1.value != $0.0.value
        }.map { (l, r) in
            let left = String(decoding: l.value, as: UTF8.self)
            let right = String(decoding: r.value, as: UTF8.self)
            return "\(l.key): \(left) != \(right)"
        }
        return changedKeys.joined(separator: "\n\n---\n\n")
    }
}


@MainActor
@Test func example() async throws {
    let base = URL.temporaryDirectory.appendingPathComponent("test")
    let out = base.appendingPathComponent("_out")
    let input = Tree.directory([
        "input.txt": "Input file",
        "posts": Tree.directory([
            "post0.md": "# Post 0",
        ]),
    ])
    try input.write(to: base)
    let view = Example()
        .staticSite(inputURL: base, outputURL: out)
        .environment(\.cleanup, false)

    let hostingView = NSHostingView(rootView: view)
    hostingView.layoutSubtreeIfNeeded()
    try await Task.sleep(for: .seconds(0.1))
    let outputTree = try Tree.read(from: out)
    let expected: Tree = .directory([
        "input.html": "Input file",
        "index.html": "Hello, world",
        "posts": Tree.directory([
            "index.html": "post0.md",
            "post0.html": "<h1>Post 0\n</h1>"
         ])
    ])
    #expect(outputTree == expected, "Expected no diff, got \(outputTree.diff(expected))")

}
