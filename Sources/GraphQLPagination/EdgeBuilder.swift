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
        switch cursor {
        case .identifier:
            let calculator = ForwardCalculator(
                cursors: nodes.map(\.cursor),
                pagination: pagination
            )
            return EdgesConstruction(
                edges: calculator.mapCursors(nodes: self.nodes, transform: self.transform),
                pageInfo: calculator.makePageInfo()
            )
        case .index:
            let calculator = ForwardCalculator(
                cursors: self.nodes.indices.map {
                    let after = pagination.after?.intValue()
                    return Cursor(intValue: after == nil ? $0 : $0)
                },
                pagination: pagination
            )
            return EdgesConstruction(
                edges: calculator.mapIndexedCursors(nodes: self.nodes, transform: self.transform),
                pageInfo: calculator.makePageInfo()
            )
        }
    }
    func makeEdges<P: GraphBackwardPaginatable>(cursor: CursorType, pagination: P) -> EdgesConstruction<Edge> {
        let calculator = BackwardCalculator(
            nodes: nodes,
            type: cursor,
            pagination: pagination
        )
        return EdgesConstruction(
            edges: calculator.mapCursors(transform: self.transform),
            pageInfo: calculator.makePageInfo()
        )
    }
}

private struct ForwardCalculator<Pagination: GraphForwardPaginatable> {
    var cursors: [Cursor]
    var pagination: Pagination
}

extension ForwardCalculator {
    func mapCursors<T, N>(nodes: [T], transform: (T, Cursor, Int) -> N) -> [N] {
        zip(self.sliced(self.cursors), self.sliced(nodes)).enumerated().map {
            transform($1.1, $1.0, $0)
        }
    }
    func mapIndexedCursors<T, N>(nodes: [T], transform: (T, Cursor, Int) -> N) -> [N] {
        if let after = self.pagination.after?.intValue() {
            return self.sliced(nodes).enumerated().map {
                transform($0.element, Cursor(intValue: after + 1 + $0.offset), $0.offset)
            }
        } else {
            return self.sliced(nodes).enumerated().map {
                transform($1, Cursor(intValue: $0), $0)
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

private extension ForwardCalculator {
    var hasPreviousPage: Bool {
        sliceInfo.afterIndex != nil
    }
    var hasNextPage: Bool {
        guard let first = pagination.first else {
            return false
        }
        if sliceInfo.afterIndex != nil {
            return cursors.count >= first + 2
        } else {
            return cursors.count >= first + 1
        }
    }
    struct SliceInfo {
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
    var sliceInfo: SliceInfo {
        guard
            let after = pagination.after,
            let afterIndex = cursors.firstIndex(where: { $0 == after })
        else {
            return SliceInfo(prefix: pagination.first)
        }
        return SliceInfo(
            afterIndex: afterIndex.advanced(by: 1),
            prefix: pagination.first
        )
    }
    func sliced<T>(_ nodes: [T]) -> ArraySlice<T> {
        precondition(nodes.count == cursors.count, "Node count must equal cursor count")
        return self.sliceInfo.slice(nodes)
    }
}

private struct BackwardCalculator<Node: GraphCursorable, Pagination: GraphBackwardPaginatable> {
    var nodes: [Node]
    var type: CursorType
    var pagination: Pagination
}

extension BackwardCalculator {
    func mapCursors<N>(transform: (Node, Cursor, Int) -> N) -> [N] {
        zip(self.sliced(self.nodes), self.sliced(self.cursors))
            .enumerated()
            .map {
                transform($0.element.0, $0.element.1, $0.offset)
            }
    }
    func makePageInfo() -> GraphPageInfo {
        let slicedCursors = self.sliceInfo.slice(self.cursors)
        return GraphPageInfo(
            hasPreviousPage: self.sliceInfo.hasPreviousPage(self.nodes.count),
            hasNextPage: self.self.sliceInfo.hasNextPage(self.nodes.count),
            startCursor: slicedCursors.first,
            endCursor: slicedCursors.last
        )
    }
}

struct Bounded<T: Equatable>: Equatable {
    let range: Range<Int>
    let nodes: [T]
    let cursors: [Cursor]
    let hasPrevious: Bool
    let hasNext: Bool
}

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

private extension BackwardCalculator {
    struct SliceInfo {
        var beforeIndex: Int?
        var subset: Int?
        func slice<T>(_ collection: [T]) -> ArraySlice<T> {
            switch (self.beforeIndex, self.subset) {
            case let (.some(beforeIndex), .some(subset)):
                return collection[(beforeIndex-subset)..<beforeIndex]
            case let (.some(beforeIndex), .none):
                return collection[0..<beforeIndex]
            case let (.none, .some(subset)):
                return collection.suffix(subset)
            case (.none, .none):
                return ArraySlice(collection)
            }
        }
        func hasPreviousPage(_ count: Int) -> Bool {
            switch (self.beforeIndex, self.subset) {
            case let (.some(beforeIndex), .some(subset)):
                return beforeIndex - subset > 0
            case let (.some(beforeIndex), .none):
                return beforeIndex < count - 1
            case let (.none, .some(suffix)):
                return suffix < count
            case (.none, .none):
                return false
            }
        }
        func hasNextPage(_ count: Int) -> Bool {
            if let index = self.beforeIndex {
                return index < count
            } else {
                return false
            }
        }
    }
    var sliceInfo: SliceInfo {
        switch self.type {
        case .identifier:
            guard
                let before = pagination.before,
                let beforeIndex = self.nodes.lastIndex(where: { $0.cursor == before })
            else {
                return SliceInfo(subset: pagination.last)
            }
            return SliceInfo(
                beforeIndex: beforeIndex,
                subset: pagination.last
            )
        case .index:
            guard
                let before = pagination.before?.intValue(),
                let beforeIndex = self.nodes.indices.lastIndex(where: { $0 == before })
            else {
                return SliceInfo(subset: pagination.last)
            }
            return SliceInfo(
                beforeIndex: beforeIndex,
                subset: pagination.last
            )

        }
    }
    var cursors: [Cursor] {
        switch self.type {
        case .identifier:
            return nodes.map(\.cursor)
        case .index:
            if let before = pagination.before?.intValue(), let last = pagination.last {
                return nodes.enumerated().map {
                    Cursor(intValue: (before - last) + $0.offset)
                }
            } else {
                return nodes.indices.map {
                    Cursor(intValue: $0)
                }
            }
        }
    }
    func sliced<T>(_ values: [T]) -> ArraySlice<T> {
        return self.sliceInfo.slice(values)
    }
}
