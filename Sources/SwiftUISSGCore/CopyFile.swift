import SwiftUI

public struct Copy: View {
    var name: String
    public init(name: String) {
        self.name = name
    }

    // TODO: this would be more efficient if we actually copy the file.
    public var body: some View {
        ReadFile(name: name) {
            Write(to: name, $0 as Data)
        }
    }
}

