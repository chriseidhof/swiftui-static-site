import Foundation
import SwiftUI
import Observation

/// Reads the contents of the current directory
public struct ReadDir<Contents: View>: View {
    var name: String?
    var contents: ([String]) -> Contents
    @State private var observer = FSObserver()
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
            contents(observer.files.filter { !$0.hasPrefix(".") })
        }
        .sideEffect(trigger: theURL) {
            observer.url = theURL
        }
    }
}

