import Testing
import Foundation
import Example
@testable import SwiftUISSG

@MainActor
@Test func example() async throws {
    let base = URL.temporaryDirectory
    let out = base.appendingPathComponent("_out")
    let view = Example().staticSite(inputURL: base, outputURL: out)
    // todo
}
