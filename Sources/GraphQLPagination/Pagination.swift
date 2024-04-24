import Foundation

public protocol GraphCursorable {
    var cursor: Cursor { get }
}

protocol GraphForwardPaginatable {
    var first: Int? { get }
    var after: Cursor? { get }
}

protocol GraphBackwardPaginatable {
    var last: Int? { get }
    var before: Cursor? { get }
}

protocol GraphPaginatable: GraphForwardPaginatable, GraphBackwardPaginatable {}

extension GraphPaginatable {
    var current: GraphCurrentPagination? {
        if self.first != nil || self.after != nil {
            return .forward(.init(first: self.first, after: self.after))
        }
        if self.last != nil || self.before != nil {
            return .backward(.init(last: self.last, before: self.before))
        }
        return nil
    }
}

enum GraphCurrentPagination {
    struct Forward: GraphForwardPaginatable {
        var first: Int?
        var after: Cursor?
    }
    struct Backward: GraphBackwardPaginatable {
        var last: Int?
        var before: Cursor?
    }
    case forward(Forward)
    case backward(Backward)
}

public struct GraphPageInfo: Equatable, Codable {
    public let hasPreviousPage: Bool
    public let hasNextPage: Bool
    public let startCursor: Cursor?
    public let endCursor: Cursor?
}

extension GraphPageInfo {
    static let zero = Self(
        hasPreviousPage: false,
        hasNextPage: false,
        startCursor: nil,
        endCursor: nil
    )
}
