import SwiftUI

struct MyLabelStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
                .foregroundStyle(.secondary)
            configuration.content
                .labeledContentStyle(MyLabelStyle())
                .padding(.leading)
        }
    }
}

