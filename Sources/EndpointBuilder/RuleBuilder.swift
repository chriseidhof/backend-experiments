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

    public static func buildOptional(_ component: (some Rule)?) -> some Rule {
        component
    }

    public static func buildEither<L, R>(first component: L) -> Either<L, R> {
        .left(component)

    }
    
    public static func buildEither<L, R>(second component: R) -> Either<L, R> {
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
