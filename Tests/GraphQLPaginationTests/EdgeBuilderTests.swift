import CustomDump
import XCTest

@testable import GraphQLPagination

final class EdgeBuilderTests: XCTestCase {

    struct TestNode: Equatable, GraphCursorable {
        let id: String
        var cursor: Cursor { .init(rawValue: self.id) }
    }
    struct TestEdge: Equatable {
        let node: TestNode
        let cursor: Cursor
        let index: Int
    }
    let a = TestNode(id: "a")
    let b = TestNode(id: "b")
    let c = TestNode(id: "c")

    func test_makeEdges() {
        let builder = EdgeBuilder(nodes: [a, b, c]) { node, cursor, index in
            TestEdge(node: node, cursor: cursor, index: index)
        }
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .identifier),
            EdgesConstruction(
                edges: [
                    TestEdge(node: a, cursor: "a", index: 0),
                    TestEdge(node: b, cursor: "b", index: 1),
                    TestEdge(node: c, cursor: "c", index: 2),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: false,
                    hasNextPage: false,
                    startCursor: "a",
                    endCursor: "c"
                )
            )
        )
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .index),
            EdgesConstruction(
                edges: [
                    TestEdge(node: a, cursor: 0, index: 0),
                    TestEdge(node: b, cursor: 1, index: 1),
                    TestEdge(node: c, cursor: 2, index: 2),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: false,
                    hasNextPage: false,
                    startCursor: 0,
                    endCursor: 2
                )
            )
        )
    }
    func test_makeEdges_empty() {
        let builder = EdgeBuilder(nodes: []) { node, cursor, index in
            TestEdge(node: node, cursor: cursor, index: index)
        }
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .identifier),
            EdgesConstruction(
                edges: [],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: false,
                    hasNextPage: false,
                    startCursor: nil,
                    endCursor: nil
                )
            )
        )
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .index),
            EdgesConstruction(
                edges: [],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: false,
                    hasNextPage: false,
                    startCursor: nil,
                    endCursor: nil
                )
            )
        )
    }
}
