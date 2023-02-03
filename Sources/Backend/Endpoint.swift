import Foundation

protocol Rule {
    associatedtype Rules: Rule
    @RuleBuilder var rules: Rules { get }

    associatedtype Body: Content
    var body: Body { get }
}

protocol BuiltinRule {
    func execute(environment: EnvironmentValues) async throws -> Response?
}

extension Rule {
    var rules: EmptyRules {
        EmptyRules()
    }
}

@resultBuilder
struct RuleBuilder {
    public static func buildPartialBlock(first: some Rule) -> some Rule {
        first
    }

    public static func buildPartialBlock(accumulated: some Rule, next: some Rule) -> some Rule {
        RulePair(r1: accumulated, r2: next)
    }

    static func buildOptional(_ component: (some Rule)?) -> some Rule {
        component
    }
}

extension Optional: BuiltinRule, Rule where Wrapped: Rule {
    func execute(environment: EnvironmentValues) async throws -> Response? {
        try await self?.execute(environment: environment)
    }
}

struct RulePair<R1: Rule, R2: Rule>: BuiltinRule, Rule {
    var r1: R1
    var r2: R2

    func execute(environment: EnvironmentValues) async throws -> Response? {
        if let r = try await r1.execute(environment: environment) {
            return r
        }
        return try await r2.execute(environment: environment)
    }
}

struct EmptyRules: BuiltinRule, Rule {
    func execute(environment: EnvironmentValues) async throws -> Response? {
        return nil
    }
}

extension Never: BuiltinRule, Rule {
    func execute(environment: EnvironmentValues) async throws -> Response? {
        return nil
    }
}

extension Never: Content {
    var toData: Data { fatalError() }
}

extension Optional: Content where Self: Content {
    var toData: Data { Data() } // todo
}

extension Rule {
    func install(environment: EnvironmentValues) {
        let m = Mirror(reflecting: self)
        for child in m.children {
            guard let dp = child.value as? DynamicProperty else { continue }
            dp.install(environment: environment)
        }
    }

    func execute(environment: EnvironmentValues) async throws -> Response? {
        if let s = self as? BuiltinRule {
            return try await s.execute(environment: environment)
        }
        install(environment: environment)
        if environment.remainingPathComponents.isEmpty {
            return Response(statusCode: .ok, body: body.toData)
        }
        return try await rules.execute(environment: environment)
    }
}

extension BuiltinRule {
    var body: Never {
        fatalError()
    }
}

struct Path<R: Rule>: Rule {
    init(_ component: String, @RuleBuilder content: () -> R) {
        self.component = component
        self.content = content()
    }

    var component: String
    @RuleBuilder var content: R

    var rules: some Rule {
        ReadPath { c in
            if c == component {
                content
            }
        }
    }

    var body: Never {
        fatalError()
    }
}

struct ReadPath<Content: Rule>: Rule {
    @RuleBuilder var content: (String) -> Content
    @Environment(\.remainingPathComponents) var remaining

    var rules: some Rule {
        if let c = remaining.first {
            content(c)
                .environment(\.remainingPathComponents, value: Array(remaining.dropFirst()))
        }
    }

    var body: Never {
        fatalError()
    }
}
