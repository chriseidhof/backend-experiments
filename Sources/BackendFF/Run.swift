import FlyingFox
import Backend

struct Nested: Rule {
    var rules: some Rule {
        ReadPath { id in
            "Subpath with id: \(id)"
        }
        "Nested rule"
    }
}

struct Home: Rule {
    var rules: some Rule {
        Nested().path("nested")
        "Hello"
    }
}

struct RuleHandler<R: Rule>: HTTPHandler {
    var rule: R

    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        // todo headers
        let request = Request(path: request.path, body: request.body)
        if let response = try await rule.execute(environment: .init(request: request)) {
            // todo status code phrase
            let code = HTTPStatusCode(response.statusCode.rawValue, phrase: "")
            return HTTPResponse(statusCode: code, headers: [:], body: response.body)
        } else {
            return .init(statusCode: .notFound)
        }
    }
}

@main struct Main {
    static func main() async throws {
        let server = HTTPServer(port: 80)
        let rules = Home()
        await server.appendRoute("*", to: RuleHandler(rule: rules))
        try await server.start()
        
    }
}
