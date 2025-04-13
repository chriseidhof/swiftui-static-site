import SwiftUI

extension View {
    public func staticSite(inputURL: URL, outputURL: URL) -> some View {
        modifier(StaticSite(inputURL: inputURL, outputURL: outputURL))
    }
}

public struct StaticSite: ViewModifier {
    public var inputURL: URL
    public var outputURL: URL
    public init(inputURL: URL, outputURL: URL) {
        self.inputURL = inputURL
        self.outputURL = outputURL
    }

    public func body(content: Content) -> some View {
        VStack(alignment: .leading) {
            Link("Base URL", destination: inputURL)
            Link("Output URL", destination: outputURL)
            content
                .frame(maxWidth: .infinity)
                .labeledContentStyle(MyLabelStyle())
                .environment(\.inputURL, inputURL)
                .environment(\.outputURL, outputURL)
        }
    }
}
