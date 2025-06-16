import Foundation
import SwiftUI

@Observable
class FSObserver<Content> {
    var url: URL? {
        didSet {
            setupDispatchSource()
        }
    }
    let read: (URL) -> Content?

    init(read: @escaping (URL) -> Content?) {
        self.read = read
    }

    var contents: Content? = nil // nil = not read
    var dispatchSource: DispatchSourceProtocol?

    func setupDispatchSource() {
        self.dispatchSource?.cancel()
        self.dispatchSource = nil

        guard let url = self.url else {
            return
        }
        let fd = open(url.path(percentEncoded: false), O_EVTONLY)
        guard fd != -1 else { return }

        let dispatchSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: [.all], queue: .main)
        dispatchSource.setEventHandler { [weak self] in
            self?.handle(event: dispatchSource.data)
        }
        dispatchSource.setCancelHandler {
            close(fd)
        }
        readHelper()
        dispatchSource.resume()
        self.dispatchSource = dispatchSource
    }

    func handle(event: DispatchSource.FileSystemEvent) {
        if event.contains(.write) {
           readHelper()
        } else if event.contains(.delete) {
            setupDispatchSource()
        } else {
            print("Other", event)
        }
    }

    func readHelper() {
        assert(Thread.current.isMainThread)
        guard let url = self.url else {
            contents = nil
            return
        }
        contents = read(url)
    }
}

public struct DirectoryContents: Codable, Hashable {
    public var files: [String]
    public init(files: [String]) {
        self.files = files
    }
}

extension FSObserver where Content == DirectoryContents {
    convenience init() {
        self.init { url in
            let fm = FileManager.default
            let files = (try? fm.contentsOfDirectory(atPath: url.path))?.sorted() ?? []
            return DirectoryContents(files: files)
        }
    }
}

extension FSObserver where Content == Data {
    convenience init() {
        self.init { url in
            try? Data(contentsOf: url)
        }
    }
}
