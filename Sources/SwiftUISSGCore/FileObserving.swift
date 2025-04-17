import Foundation
import SwiftUI

// TODO: Make it possible to construct a file observer through the environmnet
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
            read()
        }
    }
    init() {
        self.url = url
    }
    var contents: Contents = .directory([])
    var dispatchSource: Any?

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
            contents = .directory([])
            return
        }
        setupDispatchSource()
        let fm = FileManager.default
        do {
            var isDirectory: ObjCBool = false
            fm.fileExists(atPath: url.path(), isDirectory: &isDirectory)
            let newContents: Contents
            if isDirectory.boolValue {
                newContents = Contents.directory(try fm.contentsOfDirectory(atPath: url.path))
            } else {
                newContents = .file(try Data(contentsOf: url))
            }
            if newContents != contents {
                contents = newContents
            }
        } catch {
            DispatchQueue.main.async {
                log("\(error)")
            }
        }
    }
}
