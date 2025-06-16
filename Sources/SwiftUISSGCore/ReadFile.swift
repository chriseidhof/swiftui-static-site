import SwiftUI

enum FileName: Hashable {
    case relative(name: String)
    case absolute(URL)
}

public struct ReadFile<Contents: View>: View {
    var name: FileName
    var contents: (Data) -> Contents
    @State var observer = FSObserver<Data>()
    @State private var didAppear = false
    @Environment(\.inputURL) var inputURL: URL
    public init(name: String, @ViewBuilder contents: @escaping (Data) -> Contents) {
        self.name = .relative(name: name)
        self.contents = contents
    }

    public init(name: String, @ViewBuilder contents: @escaping (String) -> Contents) {
        self.name = .relative(name: name)
        self.contents = { data in
            contents(String(decoding: data, as: UTF8.self))
        }
    }

    public init(url: URL, @ViewBuilder contents: @escaping (String) -> Contents) {
        self.name = .absolute(url)
        self.contents = { data in
            contents(String(decoding: data, as: UTF8.self))
        }
    }

    var theData: Data {
        guard let d = observer.contents else {
            if didAppear {
                print("No such file: \(name) (\(inputURL))")
            }
            return Data()
        }
        return d
    }

    public var body: some View {
        LabeledContent(content: {
            contents(theData)
        }, label: {
            Text("Read \(name)")
        })
        .sideEffect(trigger: name) {
            observer.url = switch name {
            case .absolute(let url): url
            case let .relative(name: name): inputURL.appendingPathComponent(name)
            }
            didAppear = true
        }
    }
}
