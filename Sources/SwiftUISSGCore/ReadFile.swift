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

    var theData: Data {
        guard let d = observer.data else {
            print("No such file: \(name) (\(inputURL))")
            return Data()
        }
        return d
    }

    public var body: some View {
        let _ = print("ReadFile body", name)
        LabeledContent(content: {
            contents(theData)
        }, label: {
            Text("Read \(name)")
        })
        .onChange(of: name, initial: true) {
            observer.url = inputURL.appendingPathComponent(name)
        }
    }
}

