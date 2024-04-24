import CustomDump
import XCTest

@testable import GraphQLPagination

final class BasicConnectionTests: XCTestCase {

    struct TestNode: Equatable, GraphCursorable {
        let id: String
        var cursor: Cursor {
            .init(rawValue: self.id)
        }
    }

    struct TestPaging: Equatable, GraphPaginatable {
        // Forward
        var first: Int?
        var after: Cursor?
        // Backward
        var last: Int?
        var before: Cursor?
    }

    let a = TestNode(id: "a")
    let b = TestNode(id: "b")
    let c = TestNode(id: "c")
    let d = TestNode(id: "d")
    let e = TestNode(id: "e")

    func test_identifier() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c],
                pagination: TestPaging(),
                cursor: .identifier
            ),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: "a", node: a),
                    BasicEdge(cursor: "b", node: b),
                    BasicEdge(cursor: "c", node: c),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: false,
                    hasNextPage: false,
                    startCursor: "a",
                    endCursor: "c"
                )
            )
        )
    }
    func test_index() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c],
                pagination: TestPaging(),
                cursor: .index
            ),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: "0", node: a),
                    BasicEdge(cursor: "1", node: b),
                    BasicEdge(cursor: "2", node: c),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: false,
                    hasNextPage: false,
                    startCursor: "0",
                    endCursor: "2"
                )
            )
        )
    }
    func test_forward() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c, d, e],
                pagination: TestPaging(first: 3, after: "a"),
                cursor: .identifier
            ),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: "b", node: b),
                    BasicEdge(cursor: "c", node: c),
                    BasicEdge(cursor: "d", node: d),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: true,
                    hasNextPage: true,
                    startCursor: "b",
                    endCursor: "d"
                )
            )
        )
    }
    func test_backward() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c, d, e],
                pagination: TestPaging(last: 3, before: "e"),
                cursor: .identifier
            ),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: "b", node: b),
                    BasicEdge(cursor: "c", node: c),
                    BasicEdge(cursor: "d", node: d),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: true,
                    hasNextPage: true,
                    startCursor: "b",
                    endCursor: "d"
                )
            )
        )
    }
}
