import Testing
import Foundation
import Example
import SwiftUI
@testable import SwiftUISSGCore

@MainActor
@Test func example() async throws {
    let base = URL.temporaryDirectory.appendingPathComponent("test")
    let out = base.appendingPathComponent("_out")
    try FileManager.default.removeItem(at: out)
    let input = Tree.directory([
        "input.txt": "Input file",
        "posts": Tree.directory([
            "post0.md": "# Post 0",
            "post1.md": "**Post 1**",
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
    let postIndex =
    """
    <ul><li><p>post0.md
    \t\t</p>
    \t</li><li><p>post1.md
    \t\t</p>
    \t</li>
    </ul>
    """
    let expected: Tree = .directory([
        "input.txt": "Input file",
        "index.html": "Hello, world",
        "posts": Tree.directory([
            "index.html": .file(postIndex.data(using: .utf8)!),
            "post0.html": "<h1>Post 0\n</h1>",
            "post1.html": "<p><strong>Post 1</strong>\n</p>",
         ])
    ])
    #expect(outputTree == expected, "Expected no diff, got \n\(outputTree.diff(expected))")

}
