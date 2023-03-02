import FlyingFox
import EndpointBuilder
import URLEncoder


enum Route: Codable {
    case nested
    case episode(Episode)
}

struct Episode: Codable {
    var number: Int
    var route: EpisodeRoute?
}


enum EpisodeRoute: Codable {
    case edit
    case delete
}

func readEpisode(number: Int) async throws -> String? {
    if number > 3 { return "test "}
    return nil
}

extension Episode: Rule {
    func rules() async throws -> some Rule {
        if let ep = try await readEpisode(number: number) {
            switch route {
            case nil: "Ep \(number) Home"
            case .edit: "\(number) Edit"
            case .delete: "\(number) Delete"
            }
        }
    }
}

struct Home: Rule {
    var route: Route?
    func rules() -> some Rule {
        switch route {
        case nil: "Hello"
        case .nested: "Nested"
        case let .episode(e):
            e
        }
    }
}

struct RuleHandler<R: Rule>: HTTPHandler {
    var rule: (HTTPRequest) throws -> R

    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        // todo headers
        let r = Request(path: request.path, body: request.body)
        if let response = try await rule(request).execute(environment: .init(request: r)) {
            // todo status code phrase
            let code = HTTPStatusCode(response.statusCode.rawValue, phrase: "")
            return HTTPResponse(statusCode: code, headers: [:], body: response.body)
        } else {
            return .init(statusCode: .notFound, body: "Not Found".data(using: .utf8)!)
        }
    }
}

@main struct Main {
    static func main() async throws {
        let server = HTTPServer(port: 8002)
        await server.appendRoute("*", to: RuleHandler(rule: { request in
            Home(route: try decode(request.path))
        }))
        try await server.start()
        
    }
}
