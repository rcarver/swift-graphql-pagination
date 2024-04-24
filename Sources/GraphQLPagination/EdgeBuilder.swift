import Foundation

/// Describes how to create the cursor for a set of edges.
enum CursorType {
    /// The edge cursor is based on the node's `cursor` property.
    case identifier
    /// The edge cursor is based on the index of the node.
    case index
}

public protocol GraphCursorable {
    var cursor: Cursor { get }
}

struct EdgeBuilder<Node: GraphCursorable, Edge> {
    let nodes: [Node]
    let transform: (Node, Cursor, Int) -> Edge
}

struct EdgesConstruction<Edge> {
    let edges: [Edge]
    let pageInfo: GraphPageInfo
}

extension EdgesConstruction: Equatable where Edge: Equatable {}

extension EdgeBuilder {
    func makeEdges(cursor: CursorType) -> EdgesConstruction<Edge> {
        guard !self.nodes.isEmpty else {
            return EdgesConstruction(edges: [], pageInfo: .zero)
        }
        switch cursor {
        case .identifier:
            let edges = self.nodes.enumerated().map { self.transform($1, $1.cursor, $0) }
            return EdgesConstruction(edges: edges, pageInfo: GraphPageInfo(
                hasPreviousPage: false,
                hasNextPage: false,
                startCursor: nodes.first?.cursor,
                endCursor: nodes.last?.cursor
            ))
        case .index:
            let edges = self.nodes.enumerated().map { self.transform($1, Cursor(intValue: $0), $0) }
            return EdgesConstruction(edges: edges, pageInfo: GraphPageInfo(
                hasPreviousPage: false,
                hasNextPage: false,
                startCursor: Cursor(intValue: 0),
                endCursor: Cursor(intValue: nodes.count - 1)
            ))
        }
    }
    func makeEdges<P: GraphForwardPaginatable>(cursor: CursorType, pagination: P) -> EdgesConstruction<Edge> {
        let bounded = Bounded(
            type: cursor,
            forward: pagination,
            nodes: self.nodes
        )
        return EdgesConstruction(
            edges: bounded.zipped.enumerated().map { self.transform($0.element.0, $0.element.1, $0.offset) },
            pageInfo: GraphPageInfo(bounded: bounded)
        )
    }
    func makeEdges<P: GraphBackwardPaginatable>(cursor: CursorType, pagination: P) -> EdgesConstruction<Edge> {
        let bounded = Bounded(
            type: cursor,
            backward: pagination,
            nodes: self.nodes
        )
        return EdgesConstruction(
            edges: bounded.zipped.enumerated().map { self.transform($0.element.0, $0.element.1, $0.offset) },
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
        let offset = nodes.count - 1 - (backward.before?.intValue() ?? nodes.count - 1)
        let cursors = nodes.indices.map { Cursor(intValue: $0 + offset) }
        self.init(backward: backward, nodes: nodes, cursors: cursors)
    }
    private init(backward: any GraphBackwardPaginatable, nodes: [T], cursors: [Cursor]) {
        let range: Range<Int>
        switch (backward.last, backward.before) {
        case let (.some(last), .none):
            range = (nodes.count - last)..<nodes.count
        case let (.none, .some(before)):
            let index = cursors.lastIndex(where: { $0 == before }) ?? nodes.count
            range = 0..<index
        case let (.some(last), .some(before)):
            let index = cursors.lastIndex(where: { $0 == before }) ?? nodes.count
            range = (index - last)..<index
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

extension GraphPageInfo {
    init<T>(bounded: Bounded<T>) {
        self.init(
            hasPreviousPage: bounded.hasPrevious,
            hasNextPage: bounded.hasNext,
            startCursor: bounded.cursors.first,
            endCursor: bounded.cursors.last
        )
    }
}
