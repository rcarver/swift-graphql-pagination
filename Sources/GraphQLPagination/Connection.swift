import Foundation

/// The interface to create a "connection" structure in GraphQL output.
public protocol GraphConnectable {
    associatedtype Edge
    var edges: [Edge] { get }
    var pageInfo: GraphPageInfo { get }
}

/// The interface for an "edge" in GraphQL connection output.
public protocol GraphEdgeable {
    associatedtype Node
    var cursor: Cursor { get }
    var node: Node { get }
}

/// A simple connection structure.
public struct BasicConnection<Node>: GraphConnectable {
    public var edges: [BasicEdge<Node>]
    public var pageInfo: GraphPageInfo
    public init(edges: [BasicEdge<Node>], pageInfo: GraphPageInfo) {
        self.edges = edges
        self.pageInfo = pageInfo
    }
}

/// A simple edge structure.
public struct BasicEdge<Node>: GraphEdgeable {
    public var cursor: Cursor
    public var node: Node
    public init(cursor: Cursor, node: Node) {
        self.cursor = cursor
        self.node = node
    }
}

extension BasicConnection {
    /// Build a connection from nodes for any paginatable input.
    public init(
        nodes: [Node],
        pagination: any GraphPaginatable,
        cursor: CursorType
    ) where Node: GraphCursorable {
        self.init(nodes: nodes, pagination: pagination.pagination, cursor: cursor)
    }
    /// Build a connection from nodes for any forward paginatable input.
    public init(
        nodes: [Node],
        pagination: any GraphForwardPaginatable,
        cursor: CursorType
    ) where Node: GraphCursorable {
        self.init(nodes: nodes, pagination: pagination.pagination, cursor: cursor)
    }
    /// Build a connection from nodes with optional pagination input.
    public init(
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
