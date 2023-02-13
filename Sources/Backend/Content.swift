import Foundation

public protocol Content {
    var toData: Data { get }
}

extension String: Content {
    public var toData: Data {
        data(using: .utf8)!
    }
}
