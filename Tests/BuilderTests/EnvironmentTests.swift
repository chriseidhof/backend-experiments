import XCTest
@testable import EndpointBuilder

struct TitleKey: EnvironmentKey {
    static var defaultValue: String = "Default Title"
}

extension EnvironmentValues {
    var title: String {
        get { self[TitleKey.self] }
        set { self[TitleKey.self] = newValue }
    }
}

struct ReadTitle: Rule {
    @Environment(\.title) var title

    func rules() -> some Rule {
        title
    }
}

struct ModifyTitle: RuleModifier {
    @Environment(\.title) var title
    func rule(_ other: AnyRule) -> some Rule {
        other
            .environment(\.title, value: "Modified \(title)")
    }
}

// todo: test rule modifier + environment!

extension Rule {
    func test(_ path: String) async throws -> Response? {
        return try await execute(environment: .init(request: .init(path: path)))
    }
}

final class EnvironmentTests: XCTestCase {
    func testExample() async throws {
        let response = try await ReadTitle().test("/")
        XCTAssertEqual(response?.str, "Default Title")

        let response2 = try await ReadTitle().environment(\.title, value: "My Title").test("/")
        XCTAssertEqual(response2?.str, "My Title")

        let response3 = try await ReadTitle()
            .modifier(ModifyTitle())
            .environment(\.title, value: "Title")
            .test("/")
        XCTAssertEqual(response3?.str, "Modified Title")
    }

}
