import CustomDump
import XCTest

@testable import GraphQLPagination

final class CursorTests: XCTestCase {

    func test_string() throws {
        let id = Cursor(rawValue: "testing123")

        XCTAssertEqual(id.rawValue, "testing123")
        XCTAssertEqual(id.description, "dGVzdGluZzEyMw==")

        XCTAssertEqual(
            String(data: try JSONEncoder().encode(id), encoding: .utf8),
            """
            "dGVzdGluZzEyMw=="
            """
        )
    }

    func test_intValue() throws {
        let id = Cursor(intValue: 3)

        XCTAssertEqual(id.rawValue, "3")
        XCTAssertEqual(id.description, "Mw==")

        XCTAssertEqual(
            String(data: try JSONEncoder().encode(id), encoding: .utf8),
            """
            "Mw=="
            """
        )
    }

    func test_coding_roundtrip() throws {
        let id = Cursor(rawValue: "testing123")
        let encoded = try JSONEncoder().encode(id)
        let decoded = try JSONDecoder().decode(Cursor.self, from: encoded)
        XCTAssertNoDifference(id, decoded)
    }

    func test_intValue_valid() {
        let id = Cursor(intValue: 3)
        XCTAssertEqual(id.intValue(), 3)
    }
    func test_intValue_invalid() {
        let id = Cursor(rawValue: "foo")
        XCTAssertEqual(id.intValue(), nil)
    }
}
