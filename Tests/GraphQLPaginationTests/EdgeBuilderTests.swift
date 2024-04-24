import CustomDump
import XCTest

@testable import GraphQLPagination

final class BoundedTests: XCTestCase {

    typealias Forward = GraphForwardPagination
    typealias Backward = GraphBackwardPagination

    struct TestNode: Equatable, GraphCursorable {
        let id: String
        var cursor: Cursor { .init(rawValue: self.id) }
    }
    let a = TestNode(id: "a")
    let b = TestNode(id: "b")
    let c = TestNode(id: "c")
    let d = TestNode(id: "d")
    let e = TestNode(id: "e")

    func test_forward_identified() {
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(),
                identified: [a, b, c, d, e]
            ),
            Bounded(
                range: 0..<5,
                nodes: [a, b, c, d, e],
                cursors: ["a", "b", "c", "d", "e"],
                hasPrevious: false,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(first: 2),
                identified: [a, b, c, d, e]
            ),
            Bounded(
                range: 0..<2,
                nodes: [a, b],
                cursors: ["a", "b"],
                hasPrevious: false,
                hasNext: true
            )
        )
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(after: "a"),
                identified: [a, b, c, d, e]
            ),
            Bounded(
                range: 1..<5,
                nodes: [b, c, d, e],
                cursors: ["b", "c", "d", "e"],
                hasPrevious: true,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(first: 2, after: "a"),
                identified: [a, b, c, d, e]
            ),
            Bounded(
                range: 1..<3,
                nodes: [b, c],
                cursors: ["b", "c"],
                hasPrevious: true,
                hasNext: true
            )
        )
    }
    func test_forward_indexed() {
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(),
                indexed: [a, b, c, d, e]
            ),
            Bounded(
                range: 0..<5,
                nodes: [a, b, c, d, e],
                cursors: [0, 1, 2, 3, 4],
                hasPrevious: false,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(first: 2),
                indexed: [a, b, c, d, e]
            ),
            Bounded(
                range: 0..<2,
                nodes: [a, b],
                cursors: [0, 1],
                hasPrevious: false,
                hasNext: true
            )
        )
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(after: 0),
                indexed: [a, b, c, d, e]
            ),
            Bounded(
                range: 1..<5,
                nodes: [b, c, d, e],
                cursors: [1, 2, 3, 4],
                hasPrevious: true,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(first: 2, after: 0),
                indexed: [a, b, c, d, e]
            ),
            Bounded(
                range: 1..<3,
                nodes: [b, c],
                cursors: [1, 2],
                hasPrevious: true,
                hasNext: true
            )
        )
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(after: 1),
                indexed: [b, c, d, e]
            ),
            Bounded(
                range: 1..<4,
                nodes: [c, d, e],
                cursors: [2, 3, 4],
                hasPrevious: true,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(first: 2, after: 1),
                indexed: [b, c, d, e]
            ),
            Bounded(
                range: 1..<3,
                nodes: [c, d],
                cursors: [2, 3],
                hasPrevious: true,
                hasNext: true
            )
        )
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(after: 2),
                indexed: [c, d, e]
            ),
            Bounded(
                range: 1..<3,
                nodes: [d, e],
                cursors: [3, 4],
                hasPrevious: true,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(first: 2, after: 2),
                indexed: [c, d, e]
            ),
            Bounded(
                range: 1..<3,
                nodes: [d, e],
                cursors: [3, 4],
                hasPrevious: true,
                hasNext: false
            )
        )
    }
    func test_forward_invalid() {
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(first: 10),
                indexed: [a, b, c, d]
            ),
            Bounded(
                range: 0..<4,
                nodes: [a, b, c, d],
                cursors: [0, 1, 2, 3],
                hasPrevious: false,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(first: 10, after: 0),
                indexed: [a, b, c, d]
            ),
            Bounded(
                range: 1..<4,
                nodes: [b, c, d],
                cursors: [1, 2, 3],
                hasPrevious: true,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(after: 100),
                indexed: [a, b, c, d]
            ),
            Bounded(
                range: 1..<4,
                nodes: [b, c, d],
                cursors: [101, 102, 103],
                hasPrevious: true,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                forward: Forward(first: 10, after: 100),
                indexed: [a, b, c, d]
            ),
            Bounded(
                range: 1..<4,
                nodes: [b, c, d],
                cursors: [101, 102, 103],
                hasPrevious: true,
                hasNext: false
            )
        )
    }

    func test_backward_identified() {
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(),
                identified: [a, b, c, d, e]
            ),
            Bounded(
                range: 0..<5,
                nodes: [a, b, c, d, e],
                cursors: ["a", "b", "c", "d", "e"],
                hasPrevious: false,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(last: 2),
                identified: [a, b, c, d, e]
            ),
            Bounded(
                range: 3..<5,
                nodes: [d, e],
                cursors: ["d", "e"],
                hasPrevious: true,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(before: "d"),
                identified: [a, b, c, d, e]
            ),
            Bounded(
                range: 0..<3,
                nodes: [a, b, c],
                cursors: ["a", "b", "c"],
                hasPrevious: false,
                hasNext: true
            )
        )
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(last: 2, before: "d"),
                identified: [a, b, c, d, e]
            ),
            Bounded(
                range: 1..<3,
                nodes: [b, c],
                cursors: ["b", "c"],
                hasPrevious: true,
                hasNext: true
            )
        )
    }
    func test_backward_indexed() {
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(),
                indexed: [a, b, c, d, e]
            ),
            Bounded(
                range: 0..<5,
                nodes: [a, b, c, d, e],
                cursors: [0, 1, 2, 3, 4],
                hasPrevious: false,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(last: 2),
                indexed: [a, b, c, d, e]
            ),
            Bounded(
                range: 3..<5,
                nodes: [d, e],
                cursors: [3, 4],
                hasPrevious: true,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(before: 4),
                indexed: [a, b, c, d, e]
            ),
            Bounded(
                range: 0..<4,
                nodes: [a, b, c, d],
                cursors: [0, 1, 2, 3],
                hasPrevious: false,
                hasNext: true
            )
        )
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(last: 2, before: 4),
                indexed: [b, c, d, e]
            ),
            Bounded(
                range: 1..<3,
                nodes: [c, d],
                cursors: [2, 3],
                hasPrevious: true,
                hasNext: true
            )
        )
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(before: 3),
                indexed: [a, b, c, d]
            ),
            Bounded(
                range: 0..<3,
                nodes: [a, b, c],
                cursors: [0, 1, 2],
                hasPrevious: false,
                hasNext: true
            )
        )
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(last: 2, before: 3),
                indexed: [a, b, c, d]
            ),
            Bounded(
                range: 1..<3,
                nodes: [b, c],
                cursors: [1, 2],
                hasPrevious: true,
                hasNext: true
            )
        )
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(before: 2),
                indexed: [a, b, c]
            ),
            Bounded(
                range: 0..<2,
                nodes: [a, b],
                cursors: [0, 1],
                hasPrevious: false,
                hasNext: true
            )
        )
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(last: 2, before: 2),
                indexed: [a, b, c]
            ),
            Bounded(
                range: 0..<2,
                nodes: [a, b],
                cursors: [0, 1],
                hasPrevious: false,
                hasNext: true
            )
        )
    }
    func test_backward_invalid() {
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(last: 10),
                indexed: [a, b, c, d]
            ),
            Bounded(
                range: 0..<4,
                nodes: [a, b, c, d],
                cursors: [0, 1, 2, 3],
                hasPrevious: false,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(last: 4, before: 2),
                indexed: [a, b, c, d]
            ),
            Bounded(
                range: 0..<2,
                nodes: [a, b],
                cursors: [0, 1],
                hasPrevious: false,
                hasNext: true
            )
        )
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(before: 100),
                indexed: [a, b, c, d]
            ),
            Bounded(
                range: 0..<4,
                nodes: [a, b, c, d],
                cursors: [0, 1, 2, 3],
                hasPrevious: false,
                hasNext: false
            )
        )
        XCTAssertNoDifference(
            Bounded(
                backward: Backward(last: 10, before: 100),
                indexed: [a, b, c, d]
            ),
            Bounded(
                range: 0..<4,
                nodes: [a, b, c, d],
                cursors: [89, 90, 91, 92],
                hasPrevious: false,
                hasNext: false
            )
        )
    }
}

final class EdgeBuilderTests: XCTestCase {

    struct TestNode: Equatable, GraphCursorable {
        let id: String
        var cursor: Cursor { .init(rawValue: self.id) }
    }
    struct TestEdge: Equatable {
        let cursor: Cursor
        let node: TestNode
    }

    typealias Forward = GraphForwardPagination
    typealias Backward = GraphBackwardPagination

    let a = TestNode(id: "a")
    let b = TestNode(id: "b")
    let c = TestNode(id: "c")
    let d = TestNode(id: "d")

    func test_makeEdges() {
        let builder = EdgeBuilder(nodes: [a, b, c], transform: TestEdge.init)
        XCTAssertNoDifference(
            builder.makeEdges(
                cursor: .identifier
            ),
            EdgesConstruction(
                edges: [
                    TestEdge(cursor: "a", node: a),
                    TestEdge(cursor: "b", node: b),
                    TestEdge(cursor: "c", node: c),
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
            builder.makeEdges(
                cursor: .index
            ),
            EdgesConstruction(
                edges: [
                    TestEdge(cursor: 0, node: a),
                    TestEdge(cursor: 1, node: b),
                    TestEdge(cursor: 2, node: c),
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
            builder.makeEdges(
                cursor: .identifier
            ),
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
            builder.makeEdges(
                cursor: .index
            ),
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
    func test_makeEdges_forward() {
        let builder = EdgeBuilder(nodes: [a, b, c, d], transform: TestEdge.init)
        XCTAssertNoDifference(
            builder.makeEdges(
                cursor: .identifier,
                pagination: Forward(first: 3)
            ),
            EdgesConstruction(
                edges: [
                    TestEdge(cursor: "a", node: a),
                    TestEdge(cursor: "b", node: b),
                    TestEdge(cursor: "c", node: c),
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
            builder.makeEdges(
                cursor: .index,
                pagination: Forward(first: 3)
            ),
            EdgesConstruction(
                edges: [
                    TestEdge(cursor: 0, node: a),
                    TestEdge(cursor: 1, node: b),
                    TestEdge(cursor: 2, node: c),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: false,
                    hasNextPage: true,
                    startCursor: 0,
                    endCursor: 2
                )
            )
        )
    }

    func test_makeEdges_backward() {
        let builder = EdgeBuilder(
            nodes: [a, b, c, d],
            transform: TestEdge.init
        )
        XCTAssertNoDifference(
            builder.makeEdges(
                cursor: .identifier,
                pagination: Backward(last: 3)
            ),
            EdgesConstruction(
                edges: [
                    TestEdge(cursor: "b", node: b),
                    TestEdge(cursor: "c", node: c),
                    TestEdge(cursor: "d", node: d),
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
            builder.makeEdges(
                cursor: .index,
                pagination: Backward(last: 3)
            ),
            EdgesConstruction(
                edges: [
                    TestEdge(cursor: 1, node: b),
                    TestEdge(cursor: 2, node: c),
                    TestEdge(cursor: 3, node: d),
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
