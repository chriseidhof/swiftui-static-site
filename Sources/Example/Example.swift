import SwiftUI
import SwiftUISSG
import Swim

extension String {
    var baseName: String {
        .init(split(separator: ".")[0])
    }
}


struct PostIndex: View {
    var files: [String] = []
    var body: some View {
        let str = files.map { "* \($0)"}.joined(separator: "\n")
        Write(to: "index.html", str.markdown().data)
    }
}

struct Blog: View {
    var body: some View {
        ReadDir() { files in
            PostIndex(files: files)
            ForEach(files, id: \.self) { name in
                ReadFile(name: name) { contents in
                    WriteNode(name.baseName + ".html") {
                        String(decoding: contents, as: UTF8.self).markdown()
                    }
                }
            }
        }
    }
}

public struct Example: View {
    public init() { }
    
    public var body: some View {
        Write(to: "index.html", "Hello, world")
        ReadFile(name: "input.txt") { contents in
            Write(to: "input.html", contents)
        }
        Blog()
            .dir("posts")
    }
}
