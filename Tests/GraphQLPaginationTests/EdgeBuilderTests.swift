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
        let builder = EdgeBuilder(nodes: [a, b, c], transform: TestEdge.init)
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
        let builder = EdgeBuilder(nodes: [], transform: TestEdge.init)
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

final class EdgeBuilderForwardPaginationTests: XCTestCase {

    struct TestNode: Equatable, GraphCursorable {
        let id: String
        var cursor: Cursor { .init(rawValue: self.id) }
    }
    struct TestEdge: Equatable {
        let node: TestNode
        let cursor: Cursor
        let index: Int
    }
    struct Forward: GraphForwardPaginatable {
        var first: Int?
        var after: Cursor?
    }
    let a = TestNode(id: "a")
    let b = TestNode(id: "b")
    let c = TestNode(id: "c")
    let d = TestNode(id: "d")

    func test_makeEdges_first() {
        let builder = EdgeBuilder(nodes: [a, b, c, d], transform: TestEdge.init)
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .identifier, pagination: Forward(first: 3)),
            EdgesConstruction(
                edges: [
                    TestEdge(node: a, cursor: "a", index: 0),
                    TestEdge(node: b, cursor: "b", index: 1),
                    TestEdge(node: c, cursor: "c", index: 2),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: false,
                    hasNextPage: true,
                    startCursor: "a",
                    endCursor: "c"
                )
            )
        )
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .index, pagination: Forward(first: 3)),
            EdgesConstruction(
                edges: [
                    TestEdge(node: a, cursor: 0, index: 0),
                    TestEdge(node: b, cursor: 1, index: 1),
                    TestEdge(node: c, cursor: 2, index: 2),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: false,
                    hasNextPage: true,
                    startCursor: 0,
                    endCursor: 2
                )
            )
        )
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .identifier, pagination: Forward(first: 4)),
            EdgesConstruction(
                edges: [
                    TestEdge(node: a, cursor: "a", index: 0),
                    TestEdge(node: b, cursor: "b", index: 1),
                    TestEdge(node: c, cursor: "c", index: 2),
                    TestEdge(node: d, cursor: "d", index: 3),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: false,
                    hasNextPage: false,
                    startCursor: "a",
                    endCursor: "d"
                )
            )
        )
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .index, pagination: Forward(first: 4)),
            EdgesConstruction(
                edges: [
                    TestEdge(node: a, cursor: 0, index: 0),
                    TestEdge(node: b, cursor: 1, index: 1),
                    TestEdge(node: c, cursor: 2, index: 2),
                    TestEdge(node: d, cursor: 3, index: 3),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: false,
                    hasNextPage: false,
                    startCursor: 0,
                    endCursor: 3
                )
            )
        )
    }
    func test_makeEdges_after() {
        let builder = EdgeBuilder(nodes: [a, b, c, d], transform: TestEdge.init)
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .identifier, pagination: Forward(after: "a")),
            EdgesConstruction(
                edges: [
                    TestEdge(node: b, cursor: "b", index: 0),
                    TestEdge(node: c, cursor: "c", index: 1),
                    TestEdge(node: d, cursor: "d", index: 2),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: true,
                    hasNextPage: false,
                    startCursor: "b",
                    endCursor: "d"
                )
            )
        )
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .index, pagination: Forward(after: 0)),
            EdgesConstruction(
                edges: [
                    TestEdge(node: b, cursor: 1, index: 0),
                    TestEdge(node: c, cursor: 2, index: 1),
                    TestEdge(node: d, cursor: 3, index: 2),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: true,
                    hasNextPage: false,
                    startCursor: 1,
                    endCursor: 3
                )
            )
        )
    }
    func test_makeEdges_first_after() {
        let builder = EdgeBuilder(nodes: [a, b, c, d], transform: TestEdge.init)
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .identifier, pagination: Forward(first: 2, after: "a")),
            EdgesConstruction(
                edges: [
                    TestEdge(node: b, cursor: "b", index: 0),
                    TestEdge(node: c, cursor: "c", index: 1),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: true,
                    hasNextPage: true,
                    startCursor: "b",
                    endCursor: "c"
                )
            )
        )
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .index, pagination: Forward(first: 2, after: 0)),
            EdgesConstruction(
                edges: [
                    TestEdge(node: b, cursor: 1, index: 0),
                    TestEdge(node: c, cursor: 2, index: 1),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: true,
                    hasNextPage: true,
                    startCursor: 1,
                    endCursor: 2
                )
            )
        )
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .identifier, pagination: Forward(first: 3, after: "a")),
            EdgesConstruction(
                edges: [
                    TestEdge(node: b, cursor: "b", index: 0),
                    TestEdge(node: c, cursor: "c", index: 1),
                    TestEdge(node: d, cursor: "d", index: 2),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: true,
                    hasNextPage: false,
                    startCursor: "b",
                    endCursor: "d"
                )
            )
        )
        XCTAssertNoDifference(
            builder.makeEdges(cursor: .index, pagination: Forward(first: 3, after: 0)),
            EdgesConstruction(
                edges: [
                    TestEdge(node: b, cursor: 1, index: 0),
                    TestEdge(node: c, cursor: 2, index: 1),
                    TestEdge(node: d, cursor: 3, index: 2),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: true,
                    hasNextPage: false,
                    startCursor: 1,
                    endCursor: 3
                )
            )
        )
    }
}
