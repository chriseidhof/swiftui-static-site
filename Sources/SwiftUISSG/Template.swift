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

extension Node {
    func apply(_ templates: [Template], environment: EnvironmentValues) -> Node {
        templates.reversed().reduce(self) { $1.run(content: $0, environment: environment) }
    }
}

public protocol Template {
    func run(content: Node, environment: EnvironmentValues) -> Node
}

public struct IdentityTemplate: Template {
    public func run(content: Node, environment: EnvironmentValues) -> Node {
        content
    }
}

extension Template where Self == IdentityTemplate {
    public static var identity: Self {
        .init()
    }
}
