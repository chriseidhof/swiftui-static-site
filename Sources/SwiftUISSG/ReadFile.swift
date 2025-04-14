import SwiftUI

public struct ReadFile<Contents: View>: View {
    var name: String
    var contents: (Data) -> Contents
    @State var observer = FSObserver()
    @Environment(\.inputURL) var inputURL: URL
    public init(name: String, @ViewBuilder contents: @escaping (Data) -> Contents) {
        self.name = name
        self.contents = contents
    }

    public var body: some View {
        LabeledContent(content: {
            contents(observer.data!)
        }, label: {
            Text("Read \(name)")
        })
        .onChange(of: name, initial: true) {
            observer.url = inputURL.appendingPathComponent(name)
        }
    }
}

