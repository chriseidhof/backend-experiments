import Foundation

public struct EnvironmentValues {
    private var userDefined: [ObjectIdentifier:Any] = [:]
    public var request: Request
    public var remainingPathComponents: [String] = []

    public init(request: Request) {
        self.request = request
        let comps = (request.path as NSString).pathComponents
        assert(comps.first == "/")
        self.remainingPathComponents = Array(comps.dropFirst())
    }

    public subscript<Key: EnvironmentKey>(key: Key.Type = Key.self) -> Key.Value {
        get {
            userDefined[ObjectIdentifier(key)] as? Key.Value ?? Key.defaultValue
        }
        set {
            userDefined[ObjectIdentifier(key)] = newValue
        }
    }
}

public protocol EnvironmentKey {
    associatedtype Value
    static var defaultValue: Value { get }
}

protocol DynamicProperty {
    func install(environment: EnvironmentValues)
}

final class Box<A> {
    var value: A
    init(_ value: A) {
        self.value = value
    }
}

@propertyWrapper public struct Environment<Value>: DynamicProperty {
    var keyPath: KeyPath<EnvironmentValues, Value>
    var box: Box<EnvironmentValues?> = Box(nil)

    func install(environment: EnvironmentValues) {
        box.value = environment
    }

    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.keyPath = keyPath
    }

    public var wrappedValue: Value {
        guard let env = box.value else {
            fatalError("Missing environment")
        }
        return env[keyPath: keyPath]
    }
}

extension Rule {
    public func environment<Value>(_ keyPath: WritableKeyPath<EnvironmentValues, Value>, value: Value) -> some Rule {
        EnvironmentWriter(keyPath: keyPath, modify: { $0 = value }, content: self)
    }
}

struct EnvironmentWriter<Value, Content: Rule>: BuiltinRule, Rule {
    var keyPath: WritableKeyPath<EnvironmentValues, Value>
    var modify: (inout Value) -> ()
    var content: Content

    func execute(environment: EnvironmentValues) async throws -> Response? {
        var copy = environment
        modify(&copy[keyPath: keyPath])
        return try await content.execute(environment: copy)
    }
}
