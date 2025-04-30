import SwiftUI
import SwiftUISSG
import Swim
import HTML

// An example static site.
public struct Example: Rule {
    public init() { }

    public var body: some Rule {
        VStack(alignment: .leading) {
            WriteNode {
                """
                Hello, world
                
                [Blog](/posts)
                """.markdown()
            }
            Copy(name: "input.txt")
            Blog()
                .wrap(BlogTemplate())
                .dir("posts")
        }
    }
}

extension String {
    var baseName: String {
        .init(split(separator: ".")[0])
    }
}

struct PostIndex: Rule {
    var posts: [BlogPostPreference.Payload] = []
    var body: some Rule {
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

struct ProvidesBlogPost: RuleModifier {
    @Environment(\.currentPath) var path
    var title: String
    func body(content: Content) -> some Rule {
        content
            .preference(key: BlogPostPreference.self, value: [.init(title: title, absolutePath: "/\(path)")])
    }
}

extension Rule {
    func providesBlogPost(_ title: String) -> some Rule {
        modifier(ProvidesBlogPost(title: title))
    }

    func gatherBlogPosts(_ onChange: @escaping ([BlogPostPreference.Payload]) -> Void) -> some Rule {
        onPreferenceChange(BlogPostPreference.self, perform: onChange)
    }
}

struct Blog: Rule {
    @State private var posts: [BlogPostPreference.Payload] = []
    var body: some Rule {
        ReadDir() { files in
            PostIndex(posts: posts)
            ForEach(files, id: \.self) { name in
                ReadFile(name: name) { str in
                    let (frontMatter, markdown) = str.parseWithFrontMatter()
                    WriteNode {
                        markdown.markdown()
                    }
                    .providesBlogPost(frontMatter ?? name)
                    .outputDir(name.baseName)
                }
            }
        }
        .gatherBlogPosts { posts = $0 }
    }
}

struct BlogTemplate: Template {
    @NodeBuilder
    func run(content: Node) -> Node {
        h1 { %"Blog"% }
        article { content }
    }
}


