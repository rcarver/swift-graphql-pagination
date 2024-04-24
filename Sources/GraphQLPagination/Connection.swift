import Foundation

protocol GraphConnectable {
    associatedtype Edge
    var edges: [Edge] { get }
    var pageInfo: GraphPageInfo { get }
}

protocol GraphEdgeable {
    associatedtype Node
    var cursor: Cursor { get }
    var node: Node { get }
}


struct BasicConnection<Node>: GraphConnectable {
    var edges: [BasicEdge<Node>]
    var pageInfo: GraphPageInfo
}

struct BasicEdge<Node>: GraphEdgeable {
    var cursor: Cursor
    var node: Node
}

extension BasicConnection: Codable where Node: Codable {}
extension BasicConnection: Equatable where Node: Equatable {}
extension BasicEdge: Codable where Node: Codable {}
extension BasicEdge: Equatable where Node: Equatable {}

extension BasicConnection {
    init(
        nodes: [Node],
        pagination: (some GraphPaginatable)?,
        cursor: CursorType
    ) where Node: GraphCursorable {
        let (edges, pageInfo) = makeEdges(
            nodes: nodes,
            pagination: pagination,
            cursor: cursor
        ) { cursor, node, _ in
            BasicEdge(cursor: cursor, node: node)
        }
        self.edges = edges
        self.pageInfo = pageInfo
    }
}
