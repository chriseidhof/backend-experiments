import XCTest
import URLEncoder

enum Nested: Codable, Hashable {
    case index
}

struct Profile: Codable, Hashable {
    var id: String
    var profile: ProfileRoute?

}

enum ProfileRoute: Codable, Hashable {
    case edit
    case view
}

enum Users: Codable, Hashable {
    case index
    case profile(Profile?)
}

enum Route: Codable, Hashable {
    case index
    case bar
    case foo(Int)
    case label(foo: String)
    case two(Int, Int)
    case nested(Nested)
    case test(Int?)
    case test2(Bool, Int?)
    case id(UUID)
    // todo
//    case test2(String?) // todo what do we do here with nil vs. empty string?
//    case defaultValue(Int = 5)
    // TODO mirror tests in decoding (nil, UUID, escaping)
    // todo multiple (optional) values
    // default values, nil, combining nil and other parameters
}

func testDecode<R: Decodable & Equatable>(_ lhs: R?, _ rhs: String, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(lhs, try decode(rhs), file: file, line: line)
}

func testRoundtrip<R: Codable & Equatable>(_ lhs: R?, _ rhs: String, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(try encode(lhs), rhs, file: file, line: line)
    testDecode(lhs, rhs, file: file, line: line)
}

final class RoundtripTests: XCTestCase {
    func testExample() throws {
        testRoundtrip(Route.index, "/index")
        testRoundtrip(Route.bar, "/bar")
        testRoundtrip(Route.foo(5), "/foo/5")
        testRoundtrip(Route.nested(.index), "/nested/index")
        testRoundtrip(Route.label(foo: "hello"), "/label/hello")
        testRoundtrip(Route.label(foo: "hello/world"), "/label/hello%2Fworld")
        testRoundtrip(Route.two(42, 50), "/two/42/50")
        testRoundtrip(Route.test(nil), "/test")
        testRoundtrip(Route.test(1), "/test/1")
        testRoundtrip(Route.test2(true, 1), "/test2/true/1")
        testRoundtrip(Route.test2(false, nil), "/test2/false")
        let id = UUID()
        testRoundtrip(Route.id(id), "/id/\(id.uuidString)")
        testRoundtrip(Optional<Users>.none, "/")
        testRoundtrip(Users.profile(nil), "/profile")
        testRoundtrip(Users.profile(.init(id: "test")), "/profile/test")
        testRoundtrip(Users.profile(.init(id: "test", profile: .view)), "/profile/test/view")
        testDecode(Optional<Route>.none, "/")
        testDecode(Optional<Route>.none, "")
    }
}
