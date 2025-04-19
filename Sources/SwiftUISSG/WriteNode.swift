import Swim
import SwiftUI

public struct WriteNode: View {
    @NodeBuilder var builder: Node
    @Environment(\.template) var template
    var to: String
    public init(_ to: String, @NodeBuilder builder: () -> Node) {
        self.builder = builder()
        self.to = to
    }

    public var body: some View {
        Write(to: to, builder.apply(template).data)
    }
}
