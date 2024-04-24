import Foundation

/// The interface to create a "connection" structure in GraphQL output.
protocol GraphConnectable {
    associatedtype Edge
    var edges: [Edge] { get }
    var pageInfo: GraphPageInfo { get }
}

/// The interface for an "edge" in GraphQL connection output.
protocol GraphEdgeable {
    associatedtype Node
    var cursor: Cursor { get }
    var node: Node { get }
}

/// A simple connection structure.
struct BasicConnection<Node>: GraphConnectable {
    var edges: [BasicEdge<Node>]
    var pageInfo: GraphPageInfo
}

/// A simple edge structure.
struct BasicEdge<Node>: GraphEdgeable {
    var cursor: Cursor
    var node: Node
}

extension BasicConnection {
    /// Build a connection from nodes for any paginatable input.
    init(
        nodes: [Node],
        pagination: any GraphPaginatable,
        cursor: CursorType
    ) where Node: GraphCursorable {
        self.init(nodes: nodes, pagination: pagination.current, cursor: cursor)
    }
    /// Build a connection from nodes for any forward paginatable input.
    init(
        nodes: [Node],
        pagination: any GraphForwardPaginatable,
        cursor: CursorType
    ) where Node: GraphCursorable {
        self.init(nodes: nodes, pagination: pagination.current, cursor: cursor)
    }
    /// Build a connection from nodes with optional pagination input.
    init(
        nodes: [Node],
        pagination: GraphPagination?,
        cursor: CursorType
    ) where Node: GraphCursorable {
        let result = EdgeBuilder.build(
            cursor: cursor,
            nodes: nodes,
            pagination: pagination,
            transform: BasicEdge.init(cursor:node:)
        )
        self.edges = result.edges
        self.pageInfo = result.pageInfo
    }
}

extension BasicConnection: Codable where Node: Codable {}
extension BasicConnection: Equatable where Node: Equatable {}
extension BasicEdge: Codable where Node: Codable {}
extension BasicEdge: Equatable where Node: Equatable {}
