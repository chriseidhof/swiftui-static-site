import Foundation
import SwiftUI
import Observation

@Observable
class FileObserver {
    var url: URL? {
        didSet {
            read()
        }
    }
    init() {
        self.url = url
    }
    var contents: Data = .init()
    var dispatchSource: Any?

    func setupDispatchSource() {
        // not very efficient, recreating dispatch source on any change
        guard let url = self.url else {
            self.dispatchSource = nil
            return
        }
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else {
            self.dispatchSource = nil
            return
        }
        let dispatchSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: Int32(open(url.path, O_RDONLY)), eventMask: [.all])
        dispatchSource.setEventHandler { [unowned self] in
            self.read()
        }
        dispatchSource.resume()
        self.dispatchSource = dispatchSource
    }

    func read() {
        setupDispatchSource()
        let newContents: Data = url.flatMap { try? .init(contentsOf: $0) } ?? .init()
        if contents != newContents {
            contents = newContents
        }
    }
}


public struct ReadFile<Contents: View>: View {
    var name: String
    var contents: (Data) -> Contents
    @State private var observer = FileObserver()
    @Environment(\.inputURL) var inputURL: URL
    public init(name: String, @ViewBuilder contents: @escaping (Data) -> Contents) {
        self.name = name
        self.contents = contents
    }

    public var body: some View {
        LabeledContent(content: {
            contents(observer.contents)
        }, label: {
            Text("Read \(name)")
        })
        .onChange(of: name, initial: true) {
            observer.url = inputURL.appendingPathComponent(name)
        }
    }
}

