//
//  File.swift
//  
//
//  Created by Chris Eidhof on 28.06.21.
//

import Foundation
import Swim
import SwiftUI

extension EnvironmentValues {
    @Entry public var template: [Template] = []
}

extension View {
    public func wrap(_ template: Template) -> some View {
        self.transformEnvironment(\.template) { $0.append(template) }
    }
    
    public func resetTemplates() -> some View {
        self.environment(\.template, [])
    }
}

public protocol Template {
    func run(content: Node) -> Node
}
