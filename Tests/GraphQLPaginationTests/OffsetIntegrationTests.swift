import CustomDump
import XCTest
import GraphQLPagination

final class OffsetIntegrationTests: XCTestCase {
    struct Input: GraphPaginatable {
        var first: Int?
        var after: Cursor?
        var last: Int?
        var before: Cursor?
    }
    struct Node: Equatable, GraphCursorable {
        let value: Int
        var cursor: Cursor {
            Cursor(
                // 0 => "a"
                rawValue: String(Character(UnicodeScalar(self.value + 97)!))
            )
        }
    }
    let maxResults = 10
    func service(pagination: OffsetPagination) -> [Node] {
        let values = Array((pagination.offset)..<(pagination.offset + (pagination.count ?? maxResults)))
        return values.map { Node.init(value: $0) }
    }
    func test_none() {
        let input = Input()
        let nodes = self.service(pagination: input.makeOffsetPagination())
        XCTAssertEqual(nodes.count, maxResults)
        XCTAssertNoDifference(nodes.map(\.value), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        XCTAssertNoDifference(
            BasicConnection(nodes: nodes, pagination: input, cursor: .identifier),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: "a", node: Node(value: 0)),
                    BasicEdge(cursor: "b", node: Node(value: 1)),
                    BasicEdge(cursor: "c", node: Node(value: 2)),
                    BasicEdge(cursor: "d", node: Node(value: 3)),
                    BasicEdge(cursor: "e", node: Node(value: 4)),
                    BasicEdge(cursor: "f", node: Node(value: 5)),
                    BasicEdge(cursor: "g", node: Node(value: 6)),
                    BasicEdge(cursor: "h", node: Node(value: 7)),
                    BasicEdge(cursor: "i", node: Node(value: 8)),
                    BasicEdge(cursor: "j", node: Node(value: 9)),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: false,
                    hasNextPage: false,
                    startCursor: "a",
                    endCursor: "j"
                )
            )
        )
        XCTAssertNoDifference(
            BasicConnection(nodes: nodes, pagination: input, cursor: .index),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: 0, node: Node(value: 0)),
                    BasicEdge(cursor: 1, node: Node(value: 1)),
                    BasicEdge(cursor: 2, node: Node(value: 2)),
                    BasicEdge(cursor: 3, node: Node(value: 3)),
                    BasicEdge(cursor: 4, node: Node(value: 4)),
                    BasicEdge(cursor: 5, node: Node(value: 5)),
                    BasicEdge(cursor: 6, node: Node(value: 6)),
                    BasicEdge(cursor: 7, node: Node(value: 7)),
                    BasicEdge(cursor: 8, node: Node(value: 8)),
                    BasicEdge(cursor: 9, node: Node(value: 9)),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: false,
                    hasNextPage: false,
                    startCursor: 0,
                    endCursor: 9
                )
            )
        )
    }
    func test_forward_first() {
        let input = Input(first: 3)
        let nodes = self.service(pagination: input.makeOffsetPagination())
        XCTAssertEqual(nodes.count, 4)
        XCTAssertNoDifference(nodes.map(\.value), [0, 1, 2, 3])
        XCTAssertNoDifference(
            BasicConnection(nodes: nodes, pagination: input, cursor: .identifier),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: "a", node: Node(value: 0)),
                    BasicEdge(cursor: "b", node: Node(value: 1)),
                    BasicEdge(cursor: "c", node: Node(value: 2)),
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
            BasicConnection(nodes: nodes, pagination: input, cursor: .index),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: 0, node: Node(value: 0)),
                    BasicEdge(cursor: 1, node: Node(value: 1)),
                    BasicEdge(cursor: 2, node: Node(value: 2)),
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
    func test_forward_first_after() {
        let input = Input(first: 3, after: 2)
        let nodes = self.service(pagination: input.makeOffsetPagination())
        XCTAssertEqual(nodes.count, 5)
        XCTAssertNoDifference(nodes.map(\.value), [2, 3, 4, 5, 6])
        XCTAssertNoDifference(
            BasicConnection(nodes: nodes, pagination: Input(first: 3, after: "c"), cursor: .identifier),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: "d", node: Node(value: 3)),
                    BasicEdge(cursor: "e", node: Node(value: 4)),
                    BasicEdge(cursor: "f", node: Node(value: 5)),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: true,
                    hasNextPage: true,
                    startCursor: "d",
                    endCursor: "f"
                )
            )
        )
        XCTAssertNoDifference(
            BasicConnection(nodes: nodes, pagination: input, cursor: .index),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: 3, node: Node(value: 3)),
                    BasicEdge(cursor: 4, node: Node(value: 4)),
                    BasicEdge(cursor: 5, node: Node(value: 5)),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: true,
                    hasNextPage: true,
                    startCursor: 3,
                    endCursor: 5
                )
            )
        )
    }
    func test_backward_last() {
        let input = Input(last: 3)
        let nodes = self.service(pagination: input.makeOffsetPagination())
        XCTAssertEqual(nodes.count, 4)
        XCTAssertNoDifference(nodes.map(\.value), [0, 1, 2, 3])
        XCTAssertNoDifference(
            BasicConnection(nodes: nodes, pagination: input, cursor: .identifier),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: "a", node: Node(value: 0)),
                    BasicEdge(cursor: "b", node: Node(value: 1)),
                    BasicEdge(cursor: "c", node: Node(value: 2)),
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
            BasicConnection(nodes: nodes, pagination: input, cursor: .index),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: 0, node: Node(value: 0)),
                    BasicEdge(cursor: 1, node: Node(value: 1)),
                    BasicEdge(cursor: 2, node: Node(value: 2)),
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
    func test_backward_last_before() {
        let input = Input(last: 3, before: 8)
        let nodes = self.service(pagination: input.makeOffsetPagination())
        XCTAssertEqual(nodes.count, 5)
        XCTAssertNoDifference(nodes.map(\.value), [4, 5, 6, 7, 8])
        XCTAssertNoDifference(
            BasicConnection(nodes: nodes, pagination: Input(last: 3, before: "i"), cursor: .identifier),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: "f", node: Node(value: 5)),
                    BasicEdge(cursor: "g", node: Node(value: 6)),
                    BasicEdge(cursor: "h", node: Node(value: 7)),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: true,
                    hasNextPage: true,
                    startCursor: "f",
                    endCursor: "h"
                )
            )
        )
        XCTAssertNoDifference(
            BasicConnection(nodes: nodes, pagination: input, cursor: .index),
            BasicConnection(
                edges: [
                    BasicEdge(cursor: 5, node: Node(value: 5)),
                    BasicEdge(cursor: 6, node: Node(value: 6)),
                    BasicEdge(cursor: 7, node: Node(value: 7)),
                ],
                pageInfo: GraphPageInfo(
                    hasPreviousPage: true,
                    hasNextPage: true,
                    startCursor: 5,
                    endCursor: 7
                )
            )
        )
    }
}
