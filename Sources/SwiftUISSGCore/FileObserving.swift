import Foundation
import SwiftUI

// TODO: Make it possible to construct a file observer through the environmnet
@MainActor
protocol FileObserving: Observable, AnyObject {
    var url: URL? { get set }
    var files: [String] { get }
    var data: Data? { get }
}

enum Contents: Hashable, Codable {
    case file(Data)
    case directory([String])
}

@Observable
class FSObserver: FileObserving {
    var url: URL? {
        didSet {
            setupDispatchSource()
        }
    }

    init() { }

    var contents: Contents? = nil // not read
    var dispatchSource: DispatchSourceProtocol?

    var files: [String] {
        if case .directory(let list) = contents {
            return list
        } else {
            return []
        }
    }

    var data: Data? {
        if case .file(let data) = contents {
            return data
        }
        return nil
    }

    func setupDispatchSource() {
        // not very efficient, recreating dispatch source on any change
        self.dispatchSource?.cancel()
        self.dispatchSource = nil

        guard let url = self.url else {
            return
        }
        let fd = open(url.path(percentEncoded: false), O_RDONLY)
        guard fd != -1 else { return }

        let dispatchSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: [.all], queue: .main)
        dispatchSource.setEventHandler { [weak self] in
            self?.handle(event: dispatchSource.data)
        }
        dispatchSource.setCancelHandler {
            close(fd)
        }
        read()
        dispatchSource.resume()
        self.dispatchSource = dispatchSource
    }

    func handle(event: DispatchSource.FileSystemEvent) {
        if event.contains(.write) {
            read()
        } else if event.contains(.delete) {
            setupDispatchSource()
        } else {
            print("Other", event)
        }
    }

    func read() {
        assert(Thread.current.isMainThread)
        guard let url = self.url else {
            contents = nil
            return
        }
        print("Rereading", url.path(percentEncoded: false))
        let fm = FileManager.default
        do {
            var isDirectory: ObjCBool = false
            fm.fileExists(atPath: url.path(), isDirectory: &isDirectory)
            let newContents: Contents
            if isDirectory.boolValue {
                newContents = Contents.directory(try fm.contentsOfDirectory(atPath: url.path).sorted())
            } else {
                newContents = .file(try Data(contentsOf: url))
            }
            if newContents != contents {
                contents = newContents
            }
        } catch {
            log("\(error)")
        }
    }
}
