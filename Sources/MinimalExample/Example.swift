import SwiftUI
import SwiftUISSG
import Swim
import HTML

public struct StaticSite: Rule {
    public init() { }

    public var body: some Rule {
        WriteNode {
            """
            Hello, world
            
            [Blog](/posts)
            """.markdown()
        }
        Blog()
            .dir("posts")
    }
}

struct Blog: Rule {
    var body: some Rule {
        ReadDir { files in
            ForEach(files, id: \.self) { name in
                ReadFile(name: name) { contents in
                    WriteNode {
                        contents.markdown()
                    }
                    .outputDir(name.baseName)
                }
            }
        }
    }
}

extension String {
    var baseName: String {
        .init(split(separator: ".")[0])
    }
}

