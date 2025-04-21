import SwiftUI

extension EnvironmentValues {
    @Entry var inputURL: URL!
    @Entry var outputURL: URL!
    @Entry var baseOutputURL: URL!
}

extension View {
    public func inputDir(_ name: String) -> some View {
        transformEnvironment(\.inputURL) { $0.appendPathComponent(name) }
    }

    public func outputDir(_ name: String) -> some View {
        transformEnvironment(\.outputURL) { $0.appendPathComponent(name) }
    }


    /// Changes both the input and output directory
    public func dir(_ name: String) -> some View {
        LabeledContent("dir \(name)") {
            self
                .inputDir(name)
                .outputDir(name)
        }
    }
}
