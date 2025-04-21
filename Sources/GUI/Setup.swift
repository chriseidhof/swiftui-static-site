import Foundation
import SwiftUISSG

func setupExample(at url: URL) throws {
    let post0 = """
    ---
    The first post
    ---
    # Post 0
    """
    let post1 = "**Post 1**"
    let input = Tree.directory([
        "input.txt": "Input file",
        "posts": Tree.directory([
            "post0.md": .file(post0.data(using: .utf8)!),
            "post1.md": .file(post1.data(using: .utf8)!),
        ]),
    ])
    try input.write(to: url)

}
