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
            let calculator = PlusTwoPageInfoCalculator(
                cursors: nodes.map(\.cursor),
                pagination: pagination
            )
            return EdgesConstruction(
                edges: calculator.mapCursors(nodes: self.nodes, transform: self.transform),
                pageInfo: calculator.makePageInfo()
            )
        case .index:
            let calculator = PlusTwoPageInfoCalculator(
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
}

private struct PlusTwoPageInfoCalculator<Pagination: GraphForwardPaginatable> {
    var cursors: [Cursor]
    var pagination: Pagination
}

extension PlusTwoPageInfoCalculator {
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

private extension PlusTwoPageInfoCalculator {
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
