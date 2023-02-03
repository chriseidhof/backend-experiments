import Foundation

public struct Request {
    var path: String
    var headers: [(key: String, value: String)] = []
    var body: Data? = nil
}

public enum StatusCode: Int {
    case ok = 200
}

public struct Response: Hashable {
    var statusCode: StatusCode = .ok
    var body: Data = Data()
}
