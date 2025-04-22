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
    try FileManager.default.removeItem(at: base)
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
    func index(_ string: String) -> Tree {
        .directory(["index.html": .file(string.data(using: .utf8)!)])
    }
    let postIndex =
    """
    <h1>Blog</h1>
    <article>
    \t<ul>
    \t\t<li><p><a href="/posts/post0/">The first post</a></p></li>
    \t\t<li><p><a href="/posts/post1/">post1.md</a></p></li>
    \t</ul>
    </article>
    """
    let expected: Tree = .directory([
        "input.txt": "Input file",
        "index.html": """
        <p>Hello, world</p>
        <p><a href="/posts">Blog</a></p>
        """,
        "posts": Tree.directory([
            "index.html": .file(postIndex.data(using: .utf8)!),
            "post1": index("""
            <h1>Blog</h1>
            <article>
            \t<p><strong>Post 1</strong></p>
            </article>
            """),
            "post0": index("""
            <h1>Blog</h1>
            <article><h1>Post 0</h1></article>
            """)
         ])
    ])
    #expect(outputTree == expected, "Expected no diff, got \n\(outputTree.diff(expected))")

    // Check that changing the body of post0 only causes a rewrite of post0
    post0 += "\n\nUpdated in step 2"
    input[["posts", "post0.md"]] = .file(post0.data(using: .utf8)!)
    let entries0 = Log.global.entries
    try input.write(to: base)
    hostingView.layoutSubtreeIfNeeded()
    try await Task.sleep(for: .seconds(0.1))

    let entries1 = Log.global.entries
    #expect(entries1.count > entries0.count)

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
    #expect(entries2.count > entries1.count)
    #expect(entries2.last!._message == "Write posts/index.html")
}

@MainActor
@Test func testBasic() async throws {
    let base = URL.temporaryDirectory.appendingPathComponent("testBasic")
    let out = base.appendingPathComponent("_out")
    try? FileManager.default.removeItem(at: out)
    var post0 = """
    Hello, world
    """
    var input = Tree.directory([
        "post0.md": .file(post0.data(using: .utf8)!),
    ])
    try input.write(to: base)
    let view = ReadFile(name: "post0.md") {
        Write(to: "post0.md", $0)
    }
        .staticSite(inputURL: base, outputURL: out)
        .environment(\.cleanup, false)

    let hostingView = NSHostingView(rootView: view)
    hostingView.layoutSubtreeIfNeeded()
    try await Task.sleep(for: .seconds(0.1))
    let outputTree = try Tree.read(from: out)
    let expected: Tree = .directory([
        "post0.md": "Hello, world",
    ])
    #expect(outputTree == expected, "Expected no diff, got \n\(outputTree.diff(expected))")

    // Check that changing the body of post0 only causes a rewrite of post0
    post0 += "\n\nUpdated"
    input[["post0.md"]] = .file(post0.data(using: .utf8)!)
    let entries0 = Log.global.entries
    try input.write(to: base)
    hostingView.layoutSubtreeIfNeeded()
    try await Task.sleep(for: .seconds(0.1))

    let outputTree1 = try Tree.read(from: out)
    let expected1: Tree = .directory([
        "post0.md": "Hello, world\n\nUpdated",
    ])
    #expect(outputTree1 == expected1, "Expected no diff, got \n\(outputTree1.diff(expected1))")

}

@MainActor
@Test func testDir() async throws {
    let base = URL.temporaryDirectory.appendingPathComponent("testDir")
    let out = base.appendingPathComponent("_out")
    NSWorkspace.shared.open(base)
    try? FileManager.default.removeItem(at: base)
    var input = Tree.directory([
        "post0.md": .file("0".data(using: .utf8)!),
        "post1.md": .file("1".data(using: .utf8)!),
    ])
    try input.write(to: base)
    let view = ReadDir {
        Write(to: "files.md", $0.joined(separator: ","))
    }
        .staticSite(inputURL: base, outputURL: out)
        .environment(\.cleanup, false)

    let hostingView = NSHostingView(rootView: view)
    hostingView.layoutSubtreeIfNeeded()
    try await Task.sleep(for: .seconds(0.1))
    let outputTree = try Tree.read(from: out)
    let expected: Tree = .directory([
        "files.md": "_out,post0.md,post1.md",
    ])
    #expect(outputTree == expected, "Expected no diff, got \n\(outputTree.diff(expected))")

    input[["post2.md"]] = .file("3".data(using: .utf8)!)
    try input.write(to: base)
    hostingView.layoutSubtreeIfNeeded()
    try await Task.sleep(for: .seconds(0.1))

    let outputTree1 = try Tree.read(from: out)
    let expected1: Tree = .directory([
        "files.md": "_out,post0.md,post1.md,post2.md",
    ])
    #expect(outputTree1 == expected1, "Expected no diff, got \n\(outputTree1.diff(expected1))")
}
