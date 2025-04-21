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
            "post0.md": """
            ---
            The first post
            ---
            # Post 0
            """,
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
    <ul>
    \t<li><p>The first post</p></li>
    \t<li><p>post1.md</p></li>
    </ul>
    """
    let expected: Tree = .directory([
        "input.txt": "Input file",
        "index.html": "Hello, world",
        "posts": Tree.directory([
            "index.html": .file(postIndex.data(using: .utf8)!),
            "post1.html": """
            <h1>Blog</h1>
            <article>
            \t<p><strong>Post 1</strong></p>
            </article>
            """,
            "post0.html": """
            <h1>Blog</h1>
            <article><h1>Post 0</h1></article>
            """
         ])
    ])
    #expect(outputTree == expected, "Expected no diff, got \n\(outputTree.diff(expected))")

}
