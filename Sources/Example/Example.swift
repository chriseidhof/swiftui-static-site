import SwiftUI
import SwiftUISSG

extension String {
    var baseName: String {
        .init(split(separator: ".")[0])
    }
}


struct PostIndex: View {
    var files: [String] = []
    var body: some View {
        let str = files.map { "* \($0)"}.joined(separator: "\n")
        Write(str.markdown().data, to: "index.html")
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
            PostIndex(files: files)
            ForEach(files, id: \.self) { name in
                ReadFile(name: name) { contents in
                    Write(String(decoding: contents, as: UTF8.self).markdown().data, to: name.baseName + ".html")
                }
            }
        }
        .dir("posts")
    }
}
