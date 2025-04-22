import Testing
import Foundation
import Example
import SwiftUI
import SwiftUISSG
@testable import SwiftUISSGCore

@MainActor
@Test func example() async throws {
    let base = URL.temporaryDirectory.appendingPathComponent("test")
    let out = base.appendingPathComponent("_out")
    try FileManager.default.removeItem(at: out)
    var post0 = """
    ---
    The first post
    ---
    # Post 0
    """
    var post1 = "**Post 1**"
    var input = Tree.directory([
        "input.txt": "Input file",
        "posts": Tree.directory([
            "post0.md": .file(post0.data(using: .utf8)!),
            "post1.md": .file(post1.data(using: .utf8)!),
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
    <h1>Blog</h1>
    <article>
    \t<ul>
    \t\t<li><p>The first post</p></li>
    \t\t<li><p>post1.md</p></li>
    \t</ul>
    </article>
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

    // Check that changing the body of post0 only causes a rewrite of post0
    post0 += "\n\nUpdated in step 2"
    input[["posts", "post0.md"]] = .file(post0.data(using: .utf8)!)
    let entries0 = Log.global.entries
    try input.write(to: base)
    hostingView.layoutSubtreeIfNeeded()

    let entries1 = Log.global.entries
    #expect(entries1.count == entries0.count + 1)
    #expect(entries1.last!._message == "Write post0.html")

    // Check that changing the title of post1 only causes a rewrite of the blog index page.
    post1 = """
    ---
    Post 1 title
    ---
    \(post1)
    """
    input[["posts", "post1.md"]] = .file(post1.data(using: .utf8)!)
    try input.write(to: base)
    hostingView.needsLayout = true
    hostingView.layoutSubtreeIfNeeded()
    try await Task.sleep(for: .seconds(0.1)) // for the preference
    let entries2 = Log.global.entries
    #expect(entries2.count == entries1.count + 1)
    #expect(entries2.last!._message == "Write index.html")
}
