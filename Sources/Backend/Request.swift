import Foundation

public struct Request {
    public init(path: String, headers: [(key: String, value: String)] = [], body: Data? = nil) {
        self.path = path
        self.headers = headers
        self.body = body
    }

    public var path: String
    public var headers: [(key: String, value: String)] = []
    public var body: Data? = nil
}

public enum StatusCode: Int {
    case ok = 200
}

public struct Response: Hashable {
    public var statusCode: StatusCode = .ok
    public var body: Data = Data()
}

