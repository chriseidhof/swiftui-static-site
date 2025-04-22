import SwiftUI
import SwiftUISSG
import Swim
import HTML

// An example static site.
public struct Example: View {
    public init() { }

    public var body: some View {
        WriteNode { """
        Hello, world
        
        [Blog](/posts)
        """.markdown() }
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
    var posts: [BlogPostPreference.Payload] = []
    var body: some View {
        let str = posts.map { "* [\($0.title)](\($0.absolutePath))" }.joined(separator: "\n")
        WriteNode {
            str.markdown()
        }
    }
}

// As an example, we could propagate up the titles of the blog using preferences (normally, this would be the full metadata). One of the nice things about it is that (for example) the homepage could render these without having to know everything about the blog implementation.

struct BlogPostPreference: PreferenceKey {
    struct Payload: Hashable {
        var title: String
        var absolutePath: String
    }
    static var defaultValue: [Payload] { [] }
    static func reduce(value: inout [Payload], nextValue: () -> [Payload]) {
        value.append(contentsOf: nextValue())
    }
}

struct ProvidesBlogPost: ViewModifier {
    @Environment(\.currentPath) var path
    var title: String
    func body(content: Content) -> some View {
        content
            .preference(key: BlogPostPreference.self, value: [.init(title: title, absolutePath: path)])
    }
}

extension View {
    func providesBlogPost(_ title: String) -> some View {
        modifier(ProvidesBlogPost(title: title))
    }

    func gatherBlogPosts(_ onChange: @escaping ([BlogPostPreference.Payload]) -> Void) -> some View {
        onPreferenceChange(BlogPostPreference.self, perform: onChange)
    }
}

struct Blog: View {
    @State private var posts: [BlogPostPreference.Payload] = []
    var body: some View {
        ReadDir() { files in
            PostIndex(posts: posts)
            ForEach(files, id: \.self) { name in
                ReadFile(name: name) { contents in
                    let str = String(decoding: contents, as: UTF8.self)
                    let (frontMatter, markdown) = str.parseWithFrontMatter()
                    WriteNode {
                        markdown.markdown()
                    }
                    .providesBlogPost(frontMatter ?? name)
                    .outputDir(name.baseName)
                }
            }
        }
        .gatherBlogPosts {
            posts = $0
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


