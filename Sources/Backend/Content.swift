import Foundation

protocol Content {
    var toData: Data { get }
}

extension String: Content {
    var toData: Data {
        data(using: .utf8)!
    }
}
