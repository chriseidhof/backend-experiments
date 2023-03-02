import Foundation

public protocol Rule {
    associatedtype Rules: Rule
    @RuleBuilder func rules() async throws -> Rules
}

public struct AnyRule: Rule, BuiltinRule {
    let rule: any Rule
    public init<R: Rule>(_ rule: R) {
        self.rule = rule
    }

    func execute(environment: EnvironmentValues) async throws -> Response? {
        try await rule.execute(environment: environment)
    }
}

protocol BuiltinRule {
    func execute(environment: EnvironmentValues) async throws -> Response?
}

extension BuiltinRule {
    public func rules() -> Never {
        fatalError()
    }
}

extension Response: Rule, BuiltinRule {
    func execute(environment: EnvironmentValues) async throws -> Response? {
        return self
    }
}



extension Never: BuiltinRule, Rule {
    func execute(environment: EnvironmentValues) async throws -> Response? {
        return nil
    }
}

extension Never: Content {
    public var toData: Data { fatalError() }
}

extension Optional: Content where Self: Content {
    public var toData: Data { Data() } // todo
}

func install_<A>(environment: EnvironmentValues, on: A) {
    let m = Mirror(reflecting: on)
    for child in m.children {
        guard let dp = child.value as? DynamicProperty else { continue }
        dp.install(environment: environment)
    }
}

extension Rule {
    func install(environment: EnvironmentValues) {
        install_(environment: environment, on: self)
    }

    public func execute(environment: EnvironmentValues) async throws -> Response? {
        install(environment: environment)
        if let s = self as? BuiltinRule {
            return try await s.execute(environment: environment)
        }
        return try await rules().execute(environment: environment)
    }
}

extension Rule {
    public func path(_ component: String) -> some Rule {
        modifier(Path(component))
    }
}

struct Path: RuleModifier {
    init(_ component: String) {
        self.component = component
    }

    var component: String

    func rule(_ content: AnyRule) -> some Rule {
        ReadPath { c in
            if c == component {
                content
            }
        }
    }
}

public struct ReadPath<Content: Rule>: Rule {
    @RuleBuilder var content: (String) -> Content
    @Environment(\.remainingPathComponents) var remaining

    public init(@RuleBuilder content: @escaping (String) -> Content) {
        self.content = content
    }

    public func rules() -> some Rule {
        if let c = remaining.first {
            content(c)
                .environment(\.remainingPathComponents, value: Array(remaining.dropFirst()))
        }
    }
}
