//

import Foundation
import SwiftUI
import Observation

struct LogEntry: Identifiable {
    var date: Date = .now
    var id: UUID = UUID()
    var message: AnyView
    var _message: String
}

@Observable
class Log {
    var entries: [LogEntry] = []

    @MainActor static let global = Log()
}


@MainActor
public func log(_ message: String, views: AnyView? = nil) {
    print(message)
    Log.global.entries.append(.init(message: AnyView(HStack {
        Text(message)
        views
    }), _message: message))
}

public struct ConsoleView: View {
    public init() { }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(Log.global.entries) { entry in
                    LabeledContent("\(entry.date, style: .time)") {
                        HStack { entry.message }
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .monospaced()
            .frame(maxWidth: .infinity)
        }
        .background(.regularMaterial)
    }
}
