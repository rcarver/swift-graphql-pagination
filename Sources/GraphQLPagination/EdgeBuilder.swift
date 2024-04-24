import Foundation

/// Describes how to create the cursor for a set of edges.
public enum CursorType {
    /// The edge cursor is based on the node's `cursor` property.
    case identifier
    /// The edge cursor is based on the index of the node.
    case index
}

/// A type that defines its own Cursor.
public protocol GraphCursorable {
    var cursor: Cursor { get }
}

extension EdgeBuilder {
    /// Construct a set of edges from nodes.
    public static func build(
        cursor: CursorType,
        nodes: [Node],
        pagination: GraphPagination?,
        transform: @escaping (Cursor, Node) -> Edge
    ) -> EdgesConstruction<Edge> {
        let builder = EdgeBuilder(nodes: nodes, transform: transform)
        return builder.makeEdges(cursor: cursor, pagination: pagination)
    }
}

/// The result of building edges from nodes.
public struct EdgesConstruction<Edge> {
    public let edges: [Edge]
    public let pageInfo: GraphPageInfo
    public init(edges: [Edge], pageInfo: GraphPageInfo) {
        self.edges = edges
        self.pageInfo = pageInfo
    }
}

extension EdgesConstruction: Equatable where Edge: Equatable {}

/// A type that can transform a set of nodes into edges with pagination logic.
public struct EdgeBuilder<Node: GraphCursorable, Edge> {
    let nodes: [Node]
    let transform: (Cursor, Node) -> Edge
    public init(nodes: [Node], transform: @escaping (Cursor, Node) -> Edge) {
        self.nodes = nodes
        self.transform = transform
    }
}

extension EdgeBuilder {
    public func makeEdges(cursor: CursorType, pagination: GraphPagination?) -> EdgesConstruction<Edge> {
        switch pagination {
        case .none: self.makeEdges(cursor: cursor)
        case let .forward(forward): self.makeEdges(cursor: cursor, pagination: forward)
        case let .backward(backward): self.makeEdges(cursor: cursor, pagination: backward)
        }
    }
    public func makeEdges(cursor: CursorType) -> EdgesConstruction<Edge> {
        self.makeEdges(cursor: cursor, pagination: GraphForwardPagination())
    }
    public func makeEdges<P: GraphForwardPaginatable>(cursor: CursorType, pagination: P) -> EdgesConstruction<Edge> {
        let bounded = Bounded(
            type: cursor,
            forward: pagination,
            nodes: self.nodes
        )
        return EdgesConstruction(
            edges: bounded.zipped.map { self.transform($0.1, $0.0) },
            pageInfo: GraphPageInfo(bounded: bounded)
        )
    }
    public func makeEdges<P: GraphBackwardPaginatable>(cursor: CursorType, pagination: P) -> EdgesConstruction<Edge> {
        let bounded = Bounded(
            type: cursor,
            backward: pagination,
            nodes: self.nodes
        )
        return EdgesConstruction(
            edges: bounded.zipped.map { self.transform($0.1, $0.0) },
            pageInfo: GraphPageInfo(bounded: bounded)
        )
    }
}

struct Bounded<T> {
    let range: Range<Int>
    let nodes: [T]
    let cursors: [Cursor]
    let hasPrevious: Bool
    let hasNext: Bool

    var zipped: Zip2Sequence<[T], [Cursor]> {
        zip(self.nodes, self.cursors)
    }
}

extension Bounded: Equatable where T: Equatable {}

fileprivate extension Bounded {
    init(range: Range<Int>, count: Int, nodes: [T], cursors: [Cursor]) {
        self.range = range
        self.nodes = nodes
        self.cursors = cursors
        self.hasNext = range.upperBound < count
        self.hasPrevious = range.lowerBound > 0
    }
}

extension Bounded {
    init(type: CursorType, forward: any GraphForwardPaginatable, nodes: [T]) where T: GraphCursorable {
        switch type {
        case .identifier:
            self.init(forward: forward, identified: nodes)
        case .index:
            self.init(forward: forward, indexed: nodes)
        }
    }
    init(type: CursorType, backward: any GraphBackwardPaginatable, nodes: [T]) where T: GraphCursorable {
        switch type {
        case .identifier:
            self.init(backward: backward, identified: nodes)
        case .index:
            self.init(backward: backward, indexed: nodes)
        }
    }
}

extension Bounded {
    init(forward: any GraphForwardPaginatable, identified nodes: [T]) where T: GraphCursorable {
        let cursors = nodes.map(\.cursor)
        self.init(forward: forward, nodes: nodes, cursors: cursors)
    }
    init(forward: any GraphForwardPaginatable, indexed nodes: [T]) {
        let offset = forward.after?.intValue() ?? 0
        let cursors = nodes.indices.map { Cursor(intValue: $0 + offset) }
        self.init(forward: forward, nodes: nodes, cursors: cursors)
    }
    private init(forward: any GraphForwardPaginatable, nodes: [T], cursors: [Cursor]) {
        let range: Range<Int>
        switch (forward.first, forward.after) {
        case let (.some(first), .none):
            range = 0..<first
        case let (.none, .some(after)):
            let index = cursors.firstIndex(where: { $0 == after }) ?? -1
            range = (index + 1)..<nodes.count
        case let (.some(first), .some(after)):
            let index = cursors.firstIndex(where: { $0 == after }) ?? -1
            range = (index + 1)..<(index + 1 + first)
        case (.none, .none):
            range = 0..<nodes.count
        }
        self.init(
            range: range,
            count: nodes.count,
            nodes: Array(nodes[range]),
            cursors: Array(cursors[range])
        )
    }
}

extension Bounded {
    init(backward: any GraphBackwardPaginatable, identified nodes: [T]) where T: GraphCursorable {
        let cursors = nodes.map(\.cursor)
        self.init(backward: backward, nodes: nodes, cursors: cursors)
    }
    init(backward: any GraphBackwardPaginatable, indexed nodes: [T]) {
        var offset: Int = 0
        if let last = backward.last, let before = backward.before?.intValue() {
            offset = max(0, before - 1 - last)
        }
        let cursors = nodes.indices.map { Cursor(intValue: $0 + offset) }
        self.init(backward: backward, nodes: nodes, cursors: cursors)
    }
    private init(backward: any GraphBackwardPaginatable, nodes: [T], cursors: [Cursor]) {
        let range: Range<Int>
        switch (backward.last, backward.before) {
        case let (.some(last), .none):
            range = max(0, nodes.count - last)..<nodes.count
        case let (.none, .some(before)):
            let index = cursors.lastIndex(where: { $0 == before }) ?? nodes.count
            range = 0..<index
        case let (.some(last), .some(before)):
            let index = cursors.lastIndex(where: { $0 == before }) ?? nodes.count
            range = max(0, index - last)..<min(index, last)
        case (.none, .none):
            range = 0..<nodes.count
        }
        self.init(
            range: range,
            count: nodes.count,
            nodes: Array(nodes[range]),
            cursors: Array(cursors[range])
        )
    }
}

fileprivate extension GraphPageInfo {
    init<T>(bounded: Bounded<T>) {
        self.init(
            hasPreviousPage: bounded.hasPrevious,
            hasNextPage: bounded.hasNext,
            startCursor: bounded.cursors.first,
            endCursor: bounded.cursors.last
        )
    }
}
