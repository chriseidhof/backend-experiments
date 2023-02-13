import Foundation

public protocol Rule {
    associatedtype Rules: Rule
    @RuleBuilder var rules: Rules { get }
}

protocol BuiltinRule {
    func execute(environment: EnvironmentValues) async throws -> Response?
}

extension BuiltinRule {
    public var rules: Never {
        fatalError()
    }
}

extension Response: Rule, BuiltinRule {
    func execute(environment: EnvironmentValues) async throws -> Response? {
        return self
    }
}

@resultBuilder
public struct RuleBuilder {
    public static func buildPartialBlock(first: some Content) -> some Rule {
        Response(statusCode: .ok, body: first.toData)
    }

    public static func buildPartialBlock(first: some Rule) -> some Rule {
        first
    }

    public static func buildPartialBlock(accumulated: some Rule, next: some Rule) -> some Rule {
        RulePair(r1: accumulated, r2: next)
    }

    public static func buildPartialBlock(accumulated: some Rule, next: some Content) -> some Rule {
        RulePair(r1: accumulated, r2: Response(body: next.toData))
    }

    static func buildOptional(_ component: (some Rule)?) -> some Rule {
        component
    }

    static func buildEither<L, R>(first component: L) -> Either<L, R> {
        .left(component)

    }
    static func buildEither<L, R>(second component: R) -> Either<L, R> {
        .right(component)
    }
}

extension Optional: BuiltinRule, Rule where Wrapped: Rule {
    func execute(environment: EnvironmentValues) async throws -> Response? {
        try await self?.execute(environment: environment)
    }
}

public struct RulePair<R1: Rule, R2: Rule>: BuiltinRule, Rule {
    public var r1: R1
    public var r2: R2

    func execute(environment: EnvironmentValues) async throws -> Response? {
        if let r = try await r1.execute(environment: environment) {
            return r
        }
        return try await r2.execute(environment: environment)
    }
}

public enum Either<R1: Rule, R2: Rule>: BuiltinRule, Rule {
    case left(R1)
    case right(R2)

    func execute(environment: EnvironmentValues) async throws -> Response? {
        switch self {
        case .left(let l): return try await l.execute(environment: environment)
        case .right(let r): return try await r.execute(environment: environment)
        }
    }
}


public struct EmptyRules: BuiltinRule, Rule {
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
    public var toData: Data { fatalError() }
}

extension Optional: Content where Self: Content {
    public var toData: Data { Data() } // todo
}

extension Rule {
    func install(environment: EnvironmentValues) {
        let m = Mirror(reflecting: self)
        for child in m.children {
            guard let dp = child.value as? DynamicProperty else { continue }
            dp.install(environment: environment)
        }
    }

    public func execute(environment: EnvironmentValues) async throws -> Response? {
        if let s = self as? BuiltinRule {
            return try await s.execute(environment: environment)
        }
        install(environment: environment)
        return try await rules.execute(environment: environment)
    }
}

extension Rule {
    public func path(_ component: String) -> some Rule {
        Path(component, content: { self })
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
}

public struct ReadPath<Content: Rule>: Rule {
    @RuleBuilder var content: (String) -> Content
    @Environment(\.remainingPathComponents) var remaining

    public init(@RuleBuilder content: @escaping (String) -> Content) {
        self.content = content
    }

    public var rules: some Rule {
        if let c = remaining.first {
            content(c)
                .environment(\.remainingPathComponents, value: Array(remaining.dropFirst()))
        }
    }
}
