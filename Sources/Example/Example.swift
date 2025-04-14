import SwiftUI
import SwiftUISSG

public struct Example: View {
    public init() { }
    
    public var body: some View {
        Write("Hello, world", to: "index.html")
        ReadFile(name: "input.txt") { contents in
            Write(contents, to: "input.html")
        }
        ReadDir() { files in
            Write(files.joined(separator: "\n"), to: "posts.html")
            ForEach(files, id: \.self) { name in
                ReadFile(name: name) { contents in
                    Write(contents, to: name)
                }
            }
        }
        .dir("posts")
    }
}
