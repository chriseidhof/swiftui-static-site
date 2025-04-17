import SwiftUI
import SwiftUISSG

extension String {
    var baseName: String {
        .init(split(separator: ".")[0])
    }
}

public struct Example: View {
    public init() { }
    
    public var body: some View {
        Write("Hello, world", to: "index.html")
        ReadFile(name: "input.txt") { contents in
            Write(contents, to: "input.html")
        }
        ReadDir() { files in
            Write(files.joined(separator: "\n"), to: "index.html")
            ForEach(files, id: \.self) { name in
                ReadFile(name: name) { contents in
                    Write(contents, to: name.baseName + ".html")
                }
            }
        }
        .dir("posts")
    }
}
