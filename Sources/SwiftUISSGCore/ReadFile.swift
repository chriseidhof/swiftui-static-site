import SwiftUI

public struct ReadFile<Contents: View>: View {
    var name: String
    var contents: (Data) -> Contents
    @State var observer = FSObserver<Data>()
    @State private var didAppear = false
    @Environment(\.inputURL) var inputURL: URL
    public init(name: String, @ViewBuilder contents: @escaping (Data) -> Contents) {
        self.name = name
        self.contents = contents
    }

    public init(name: String, @ViewBuilder contents: @escaping (String) -> Contents) {
        self.name = name
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
            observer.url = inputURL.appendingPathComponent(name)
            didAppear = true
        }
    }
}
