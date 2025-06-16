import SwiftUI
import BasicGUI
import Example

struct ContentView: View {
    @State var didAppear: Bool = false
    var base = URL.temporaryDirectory.appendingPathComponent("app")
    var body: some View {
        ZStack {
            if didAppear {
                GUIView(site: Example(), base: base)
            } else {
                ProgressView()
            }
        }.onAppear {
            try! setupExample(at: base)
            didAppear = true
        }
    }
}

