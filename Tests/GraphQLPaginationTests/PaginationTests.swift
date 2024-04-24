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

    func test_noPagination_cursorIdentifier() async throws {
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
    func test_noPagination_cursorIndex() async throws {
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
    func test_first() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c, d],
                pagination: TestPaging(
                    first: 3
                ),
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
                    hasNextPage: true,
                    startCursor: "a",
                    endCursor: "c"
                )
            )
        )
    }
    func test_after_cursorId() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c, d],
                pagination: TestPaging(
                    after: "a"
                ),
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
                    hasNextPage: false,
                    startCursor: "b",
                    endCursor: "d"
                )
            )
        )
    }
    func test_after_cursorIndex() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c, d],
                pagination: TestPaging(
                    after: "1"
                ),
                cursor: .index
            ),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: "2", node: b),
                    BasicEdge(cursor: "3", node: c),
                    BasicEdge(cursor: "4", node: d),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: true,
                    hasNextPage: false,
                    startCursor: "2",
                    endCursor: "4"
                )
            )
        )
    }
    func test_firstAfter_hasNextPage() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c, d, e],
                pagination: TestPaging(
                    first: 3,
                    after: "a"
                ),
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
    func test_firstAfter_notHasNextPage() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c, d],
                pagination: TestPaging(
                    first: 3,
                    after: "a"
                ),
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
                    hasNextPage: false,
                    startCursor: "b",
                    endCursor: "d"
                )
            )
        )
    }

    func test_last() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c, d],
                pagination: TestPaging(
                    last: 3
                ),
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
                    hasNextPage: false,
                    startCursor: "b",
                    endCursor: "d"
                )
            )
        )
    }
    func test_before_cursorId() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c, d],
                pagination: TestPaging(
                    before: "d"
                ),
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
                    hasNextPage: true,
                    startCursor: "a",
                    endCursor: "c"
                )
            )
        )
    }
    func test_before_cursorIndex() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c, d],
                pagination: TestPaging(
                    before: "3"
                ),
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
                    hasNextPage: true,
                    startCursor: "0",
                    endCursor: "2"
                )
            )
        )
    }
    func test_lastBefore_hasNextPage_hasPreviousPage() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c, d, e],
                pagination: TestPaging(
                    last: 3,
                    before: "e"
                ),
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
    func test_lastBefore_notHasPreviousPage() async throws {
        XCTAssertNoDifference(
            BasicConnection(
                nodes: [a, b, c, d],
                pagination: TestPaging(
                    last: 3,
                    before: "d"
                ),
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
                    hasNextPage: true,
                    startCursor: "a",
                    endCursor: "c"
                )
            )
        )
    }
}
