public protocol RuleModifier: DynamicProperty {
    associatedtype Rules: Rule
    @RuleBuilder func rule(_ other: AnyRule) -> Rules
}

struct Modified<R: Rule, M: RuleModifier>: Rule, BuiltinRule {
    var content: R
    var modifier: M

    func execute(environment: EnvironmentValues) async throws -> Response? {
        return try await modifier.rule(AnyRule(content)).execute(environment: environment)
    }
}

extension Rule {
    func modifier<M: RuleModifier>(_ modifier: M) -> some Rule {
        Modified(content: self, modifier: modifier)
    }
}
