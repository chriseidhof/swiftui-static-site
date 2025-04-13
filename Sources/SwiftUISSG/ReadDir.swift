import Foundation
import SwiftUI
import Observation

@Observable
class DirectoryObserver {
    var url: URL? {
        didSet {
            read()
        }
    }
    init() {
        self.url = url
    }
    var files: [String] = []
    var dispatchSource: Any?

    func setupDispatchSource() {
        // not very efficient, recreating dispatch source on any change
        guard let url = self.url else {
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
        guard let url = self.url else {
            files = []
            return
        }
        setupDispatchSource()
        let fm = FileManager.default
        do {
            let newContents = try fm.contentsOfDirectory(atPath: url.path)
            if newContents != files {
                files = newContents
            }
        } catch {
            DispatchQueue.main.async {
                log("\(error)")
            }
        }
    }
}


public struct ReadDir<Contents: View>: View {
    var name: String?
    var contents: ([String]) -> Contents
    @State private var observer = DirectoryObserver()
    @Environment(\.inputURL) var inputURL: URL
    public init(name: String? = nil, @ViewBuilder contents: @escaping ([String]) -> Contents) {
        self.name = name
        self.contents = contents
    }

    var theURL: URL {
        name.map { inputURL.appendingPathComponent($0) } ?? inputURL
    }

    public var body: some View {
        let theName = theURL.lastPathComponent
        LabeledContent("Read Dir \(theName)") {
            contents(observer.files)
        }
        .onChange(of: theURL, initial: true) {
            observer.url = theURL
        }
    }
}

