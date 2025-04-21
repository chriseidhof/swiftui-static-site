import Foundation

enum Tree: Hashable {
    case file(Data)
    case directory([String: Tree])
}

extension Tree: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self = .file(value.data(using: .utf8)!)
    }
}

extension Tree: CustomStringConvertible {
    func pretty(indent: String = "") -> String {
        switch self {
        case .directory(let items):
            return items.map { (key, value) in
                "\(indent)\(key):\n" +
                "\(indent)\(value.pretty(indent: indent + "  "))"
            }.joined(separator: "\n")
        case .file(let d):
            return "\"\(String(decoding: d, as: UTF8.self))\""
        }
    }

    var description: String {
        pretty()
    }
}

extension Tree {
    func write(to url: URL) throws {
        switch self {
        case .file(let f):
            try f.write(to: url)
        case .directory(let d):
            let fm = FileManager.default
            if !fm.fileExists(atPath: url.path()) {
                try fm.createDirectory(at: url, withIntermediateDirectories: true)
            }
            for (key, value) in d {
                try value.write(to: url.appendingPathComponent(key))
            }
        }
    }

    static func read(from: URL) throws -> Tree {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: from.path(), isDirectory: &isDir) else {
            fatalError()
        }
        if isDir.boolValue {
            // read dir
            let contents = try fm.contentsOfDirectory(atPath: from.path())
                .filter { !$0.hasPrefix(".") }
            return .directory(.init(uniqueKeysWithValues: try contents.map {
                try ($0, .read(from: from.appendingPathComponent($0)))
            }))

        } else {
            return try .file(Data(contentsOf: from))
        }
    }
}

extension Tree {
    func flattenHelper(into: inout [String: Data], prefix: [String]) {
        switch self {
        case .file(let data):
            into[prefix.joined(separator: "/")] = data
        case .directory(let dictionary):
            for (key, value) in dictionary {
                value.flattenHelper(into: &into, prefix: prefix + [key])
            }
        }
    }

    func flatten() -> [String: Data] {
        var result: [String: Data] = [:]
        flattenHelper(into: &result, prefix: [])
        return result
    }

    func diff(_ other: Tree) -> String {
        let src = flatten().sorted { $0.key < $1.key }
        let otherFlat = other.flatten()
        let dst = otherFlat.sorted { $0.key < $1.key }
        let keysDiff = dst.map(\.key).difference(from: src.map(\.key))
        guard keysDiff.isEmpty else {
            return (keysDiff.removals.map { "Removed: \($0)" } + keysDiff.insertions.map { "Added: \($0)" }).joined(separator: "\n")
        }
        let changedKeys = zip(src, dst).filter {
            $0.1.value != $0.0.value
        }.map { (l, r) in
            let left = String(decoding: l.value, as: UTF8.self)
            let right = String(decoding: r.value, as: UTF8.self)
            return "\(l.key):\n\(left.diff(other: right))"
        }
        return changedKeys.joined(separator: "\n\n---\n\n")
    }
}

extension Tree {
    subscript(path: [String]) -> Tree {
        get {
            guard let f = path.first else {
                return self
            }
            guard case .directory(let dictionary) = self else {
                fatalError()
            }
            return dictionary[f]![Array(path.dropFirst())]
        }
        set {
            guard let f = path.first else {
                self = newValue
                return
            }
            guard case .directory(var dictionary) = self else {
                fatalError()
            }
            dictionary[f]![Array(path.dropFirst())] = newValue
            self = .directory(dictionary)
        }
    }
}

extension String {
    // TODO: git-like diff
    func diff(other: String) -> String {
        let lines = self.split(separator: "\n")
        let otherLines = other.split(separator: "\n")
        let diff = lines.difference(from: otherLines)
        let result: [String] = diff.map { change -> String in
            switch change {

            case .insert(offset: let offset, element: let element, associatedWith: let associatedWith):
                return "+[\(offset)]: \(String(element))"
            case .remove(offset: let offset, element: let element, associatedWith: let associatedWith):
                return "-[\(offset)]: \(String(element))"
            }
        }
        return result.joined(separator: "\n")
    }
}


