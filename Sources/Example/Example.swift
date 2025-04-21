import SwiftUI
import SwiftUISSG
import Swim
import HTML

// An example static site.
public struct Example: View {
    public init() { }

    public var body: some View {
        Write(to: "index.html", "Hello, world")
        Copy(name: "input.txt")
        Blog()
            .wrap(BlogTemplate())
            .dir("posts")
    }
}

extension String {
    var baseName: String {
        .init(split(separator: ".")[0])
    }
}

struct PostIndex: View {
    var titles: [String] = []
    var body: some View {
        let str = titles.map { "* \($0)"}.joined(separator: "\n")
        Write(to: "index.html", str.markdown().data)
    }
}

// As an example, we could propagate up the titles of the blog using preferences (normally, this would be the full metadata). One of the nice things about it is that (for example) the homepage could render these without having to know everything about the blog implementation.

struct BlogTitlesPreference: PreferenceKey {
    static var defaultValue: [String] { [] }
    static func reduce(value: inout [String], nextValue: () -> [String]) {
        value.append(contentsOf: nextValue())
    }
}

extension View {
    func blogPostTitle(_ title: String) -> some View {
        preference(key: BlogTitlesPreference.self, value: [title])
    }

    func gatherBlogPostTitles(_ onChange: @escaping ([String]) -> Void) -> some View {
        onPreferenceChange(BlogTitlesPreference.self, perform: onChange)
    }
}

struct Blog: View {
    @State private var postTitles: [String] = []
    var body: some View {
        ReadDir() { files in
            PostIndex(titles: postTitles)
            ForEach(files, id: \.self) { name in
                ReadFile(name: name) { contents in
                    let str = String(decoding: contents, as: UTF8.self)
                    let (frontMatter, markdown) = str.parseWithFrontMatter()
                    WriteNode(name.baseName + ".html") {
                        markdown.markdown()
                    }
                    .blogPostTitle(frontMatter ?? name)
                }
            }
        }
        .gatherBlogPostTitles {
            postTitles = $0
        }
    }
}

struct BlogTemplate: Template {
    @NodeBuilder
    func run(content: Node) -> Node {
        h1 { %"Blog"% }
        article { content }
    }
}


