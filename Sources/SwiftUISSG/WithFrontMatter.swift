import Foundation

extension String {
    // Parses a yaml front matter delimeted by ---
    public func parseWithFrontMatter() -> (frontmatter: String?, markdown: String) {
        var remainder = self[...]
        remainder.remove(while: { $0.isWhitespace })
        guard remainder.remove(prefix: "---") else {
            return (frontmatter: nil, markdown: self)
        }
        let start = remainder.startIndex
        var end = remainder.startIndex
        while !remainder.isEmpty, !remainder.remove(prefix: "---") {
            remainder.removeLine()
            end = remainder.startIndex
        }
        let yaml = String(self[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
        return (frontmatter: yaml, markdown: String(remainder))
    }
}
