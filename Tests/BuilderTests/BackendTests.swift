import XCTest
@testable import EndpointBuilder
import URLEncoder

extension Response {
    var str: String {
        String(decoding: body, as: UTF8.self)
    }
}

struct Hello: Rule {
    func rules() -> some Rule {
        "Hello"
    }
}

struct Profile: Rule {
    var id: String
    var route: ProfileRoute?

    func rules() -> some Rule {
        if let r = route {
            switch r {
            case .index: "Profile"
            case .edit: "Edit"
            case .delete: "Delete"
            }
        }
    }
}

struct Users: Rule {
    var route: UsersRoute?
    func rules() -> some Rule {
        if let r = route, case let .profile(id, route) = r {
            Profile(id: id, route: route)
        } else {
            "User List"
        }
    }
}

enum ProfileRoute: Hashable, Codable {
    case index
    case edit
    case delete
}

enum UsersRoute: Hashable, Codable {
    case index
    case profile(String, ProfileRoute)
}

extension Rule {
    func test(route: UsersRoute) async throws -> Response? {
        let path = try encode(route)
        return try await execute(environment: .init(request: .init(path: path)))
    }
}

extension Users {
    func parse(_ path: String) async throws -> Response? {
        var copy = self
        copy.route = try decode(path)
        return try await copy.execute(environment: .init(request: .init(path: path)))
    }
}

final class BackendTests: XCTestCase {
    func testExample() async throws {
        let response = try await Hello().test("/")
        XCTAssertEqual(response?.str, "Hello")
    }

    func testUsers() async throws {
        let response = try await Users().parse("/")
        XCTAssertEqual(response?.str, "User List")

        let response1 = try await Users().parse("/profile/florian/index")
        XCTAssertEqual(response1?.str, "Profile")

        let response2 = try await Users().parse("/profile/florian/edit")
        XCTAssertEqual(response2?.str, "Edit")

        let response3 = try await Users().parse("/profile/florian/delete")
        XCTAssertEqual(response3?.str, "Delete")

        do {
            let response4 = try await Users().parse("/profile/florian/foo")
            XCTFail()
        } catch {
        }
    }
}
