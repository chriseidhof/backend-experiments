import XCTest
@testable import Backend

extension Response {
    var str: String {
        String(decoding: body, as: UTF8.self)
    }
}

struct Hello: Rule {
    var body: String {
        "Hello"
    }
}

struct Text: Rule {
    var text: String
    init(_ text: String) {
        self.text = text
    }

    var body: String {
        text
    }
}

struct Profile: Rule {
    var id: String

    var rules: some Rule {
        Path("edit") { Text("Edit") }
        Path("delete") { Text("Delete") }
    }

    var body: String {
        "Profile"
    }
}

struct Users: Rule {
    var rules: some Rule {
        ReadPath { str in
            Profile(id: str)
        }
    }

    var body: String {
        "User List"
    }
}

enum ProfileRoute: Hashable {
    case edit
    case delete
}

enum UsersRoute: Hashable {
    case profile(id: String, ProfileRoute)
}

final class BackendTests: XCTestCase {
    func testExample() async throws {
        let response = try await Hello().test("/")
        XCTAssertEqual(response?.str, "Hello")
    }

    func testUsers() async throws {
        let response = try await Users().test("/")
        XCTAssertEqual(response?.str, "User List")

        let response1 = try await Users().test("/florian")
        XCTAssertEqual(response1?.str, "Profile")

        let response2 = try await Users().test("/florian/edit")
        XCTAssertEqual(response2?.str, "Edit")

        let response3 = try await Users().test("/florian/delete")
        XCTAssertEqual(response3?.str, "Delete")

        let response4 = try await Users().test("/florian/foo")
        XCTAssertEqual(response4, nil)
    }
}
