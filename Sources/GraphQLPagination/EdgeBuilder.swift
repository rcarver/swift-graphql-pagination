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
            let edges = nodes.enumerated().map { self.transform($1, $1.cursor, $0) }
            return EdgesConstruction(edges: edges, pageInfo: GraphPageInfo(
                hasPreviousPage: false,
                hasNextPage: false,
                startCursor: nodes.first?.cursor,
                endCursor: nodes.last?.cursor
            ))
        case .index:
            let edges = nodes.enumerated().map { self.transform($1, Cursor(intValue: $0), $0) }
            return EdgesConstruction(edges: edges, pageInfo: GraphPageInfo(
                hasPreviousPage: false,
                hasNextPage: false,
                startCursor: Cursor(intValue: 0),
                endCursor: Cursor(intValue: nodes.count - 1)
            ))
        }
    }
//    func makeEdges<P: GraphPaginatable>(pagionation: P) -> EdgesConstruction<Edge> {
//
//    }
}

/// Turns a set of nodes and pagination in to edges.
func makeEdges<Node: GraphCursorable, P: GraphPaginatable, Edge>(
    nodes: [Node],
    pagination: P?,
    cursor: CursorType,
    makeEdge: (Cursor, Node, Int) -> Edge
) -> (edges: [Edge], pageInfo: GraphPageInfo) {
    if let pagination {
        switch cursor {
        case .identifier:
            let calculator = PlusTwoPageInfoCalculator(
                cursors: nodes.map(\.cursor),
                pagination: pagination
            )
            let edges = calculator.mapCursors(nodes: nodes, transform: makeEdge)
            let pageInfo = calculator.makePageInfo()
            return (edges, pageInfo)
        case .index:
            let calculator = PlusTwoPageInfoCalculator(
                cursors: nodes.indices.map {
                    switch pagination.current {
                    case let .forward(forward):
                        let after = forward.after?.intValue()
                        return Cursor(intValue: after == nil ? $0 : after! + $0)
                    case let .backward(backward):
                        return Cursor(intValue: $0)
                    case .none:
                        return Cursor(intValue: $0)
                    }
                },
                pagination: pagination
            )
            let edges = calculator.mapIndexedCursors(nodes: nodes, transform: makeEdge)
            let pageInfo = calculator.makePageInfo()
            return (edges, pageInfo)
        }
    } else {
        switch cursor {
        case .identifier:
            let edges = nodes.enumerated().map { makeEdge($1.cursor, $1, $0) }
            return (edges, .zero)
        case .index:
            let edges = nodes.enumerated().map { makeEdge(Cursor(intValue: $0), $1, $0) }
            return (edges, .zero)
        }
    }
}

private struct PlusTwoPageInfoCalculator<Pagination: GraphPaginatable> {
    var cursors: [Cursor]
    var pagination: Pagination
}

extension PlusTwoPageInfoCalculator {
    func mapCursors<T, N>(nodes: [T], transform: (Cursor, T, Int) -> N) -> [N] {
        zip(self.sliced(self.cursors), self.sliced(nodes)).enumerated().map { transform($1.0, $1.1, $0) }
    }
    func mapIndexedCursors<T, N>(nodes: [T], transform: (Cursor, T, Int) -> N) -> [N] {
        switch self.pagination.current {
        case let .forward(forward):
            if let after = forward.after?.intValue() {
                return self.sliced(nodes).enumerated().enumerated().map {
                    transform(Cursor(intValue: after + 1 + $1.0), $1.1, $0)
                }
            } else {
                return self.sliced(nodes).enumerated().map {
                    transform(Cursor(intValue: $0), $1, $0)
                }
            }
        case .backward:
            return self.sliced(nodes).enumerated().map {
                transform(Cursor(intValue: $0), $1, $0)
            }
        case .none:
            return self.sliced(nodes).enumerated().map {
                transform(Cursor(intValue: $0), $1, $0)
            }
        }
    }
    func makePageInfo() -> GraphPageInfo {
        let slicedCursors = self.sliceInfo.slice(self.cursors)
        return GraphPageInfo(
            hasPreviousPage: self.hasPreviousPage,
            hasNextPage: self.hasNextPage,
            startCursor: slicedCursors.first,
            endCursor: slicedCursors.last
        )
    }
}

private extension PlusTwoPageInfoCalculator {
    var hasPreviousPage: Bool {
        switch self.sliceInfo {
        case let .forward(sliceInfo):
            if let index = sliceInfo.afterIndex {
                return index > 0
            } else {
                return false
            }
        case let .backward(sliceInfo):
            switch (sliceInfo.beforeIndex, sliceInfo.count) {
            case let (.some(index), .some(count)):
                return index - count > 0
            case (.some, .none):
                return false
            case let (.none, .some(count)):
                return count < self.cursors.count
            case (.none, .none):
                return false
            }
        }
    }
    var hasNextPage: Bool {
        switch self.sliceInfo {
        case let .forward(sliceInfo):
            guard let first = pagination.first else {
                return false
            }
            if sliceInfo.afterIndex != nil {
                return cursors.count >= first + 2
            } else {
                return cursors.count >= first + 1
            }
        case let .backward(sliceInfo):
            return sliceInfo.beforeIndex != nil
        }
    }
    enum SliceInfo {
        case forward(ForwardSliceInfo)
        case backward(BackwardSliceInfo)
        func slice<T>(_ collection: [T]) -> ArraySlice<T> {
            switch self {
            case let .forward(s): s.slice(collection)
            case let .backward(s): s.slice(collection)
            }
        }
    }
    struct ForwardSliceInfo {
        var afterIndex: Int?
        var prefix: Int?
        func slice<T>(_ collection: [T]) -> ArraySlice<T> {
            switch (self.afterIndex, self.prefix) {
            case let (.some(afterIndex), .some(prefix)):
                return collection[afterIndex...].prefix(prefix)
            case let (.some(afterIndex), .none):
                return collection[afterIndex...]
            case let (.none, .some(prefix)):
                return collection.prefix(prefix)
            case (.none, .none):
                return ArraySlice(collection)
            }
        }
    }
    struct BackwardSliceInfo {
        var beforeIndex: Int?
        var count: Int?
        func slice<T>(_ collection: [T]) -> ArraySlice<T> {
            switch (self.beforeIndex, self.count) {
            case let (.some(beforeIndex), .some(count)):
                return collection[0..<beforeIndex].suffix(count)
            case let (.some(beforeIndex), .none):
                guard beforeIndex > 0 else { return [] }
                return collection[0..<beforeIndex]
            case let (.none, .some(prefix)):
                return collection.suffix(prefix)
            case (.none, .none):
                return ArraySlice(collection)
            }
        }
    }
    var sliceInfo: SliceInfo {
        switch self.pagination.current {
        case let .forward(forward):
            guard
                let after = forward.after,
                let afterIndex = cursors.firstIndex(where: { $0 == after })
            else {
                return .forward(ForwardSliceInfo(prefix: forward.first))
            }
            return .forward(ForwardSliceInfo(
                afterIndex: afterIndex.advanced(by: 1),
                prefix: forward.first
            ))
        case let .backward(backward):
            guard
                let before = backward.before,
                let beforeIndex = cursors.lastIndex(where: { $0 == before })
            else {
                return .backward(BackwardSliceInfo(count: backward.last))
            }
            return .backward(BackwardSliceInfo(
                beforeIndex: beforeIndex,
                count: backward.last
            ))
        case .none:
            return .forward(ForwardSliceInfo())
        }
    }
    func sliced<T>(_ nodes: [T]) -> ArraySlice<T> {
        precondition(nodes.count == cursors.count, "Node count must equal cursor count")
        return self.sliceInfo.slice(nodes)
    }
}
