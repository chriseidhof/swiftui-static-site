import SwiftUI

struct ChangeEffectModifier<Value: Equatable>: ViewModifier {
    var value: Value
    @State var visible: Bool = false
    func body(content: Content) -> some View {
        content
            .overlay {
                if visible {
                    Color.blue
                }
            }
            .onChange(of: value) {
                visible = true
                withAnimation(.default.delay(0.3)) {
                    visible = false
                }
            }
    }
}

extension View {
    func changeEffect<Value: Equatable>(trigger: Value) -> some View {
        modifier(ChangeEffectModifier(value: trigger))
    }
}

