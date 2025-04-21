import SwiftUI

extension View {
    func sideEffect<Trigger: Equatable>(trigger: Trigger, action: @escaping () -> ()) -> some View {
        onChange(of: trigger, initial: true, action)
    }
}
