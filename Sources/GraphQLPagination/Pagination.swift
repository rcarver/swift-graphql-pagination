import Foundation

/// The interface describing forward pagination inputs.
protocol GraphForwardPaginatable {
    var first: Int? { get }
    var after: Cursor? { get }
}

/// The interface describing backward pagination inputs.
protocol GraphBackwardPaginatable {
    var last: Int? { get }
    var before: Cursor? { get }
}

/// The interface describing pagination inputs.
protocol GraphPaginatable: GraphForwardPaginatable, GraphBackwardPaginatable {}

extension GraphForwardPaginatable {
    /// Construct the real pagination from available inputs.
    var current: GraphPagination? {
        if self.first != nil || self.after != nil {
            return .forward(.init(first: self.first, after: self.after))
        }
        return nil
    }
}

extension GraphPaginatable {
    /// Construct the real pagination from available inputs.
    var current: GraphPagination? {
        if self.first != nil || self.after != nil {
            return .forward(.init(first: self.first, after: self.after))
        }
        if self.last != nil || self.before != nil {
            return .backward(.init(last: self.last, before: self.before))
        }
        return nil
    }
}

/// Real pagination inputs.
enum GraphPagination {
    case forward(GraphForwardPagination)
    case backward(GraphBackwardPagination)
}

/// A concrete forward pagination input.
struct GraphForwardPagination: GraphForwardPaginatable {
    var first: Int?
    var after: Cursor?
    public init(first: Int? = nil, after: Cursor? = nil) {
        self.first = first
        self.after = after
    }
}

/// A concrete backward pagination input.
struct GraphBackwardPagination: GraphBackwardPaginatable {
    var last: Int?
    var before: Cursor?
    public init(last: Int? = nil, before: Cursor? = nil) {
        self.last = last
        self.before = before
    }
}

/// Describes the state of pagination for output.
public struct GraphPageInfo: Equatable, Codable {
    public let hasPreviousPage: Bool
    public let hasNextPage: Bool
    public let startCursor: Cursor?
    public let endCursor: Cursor?
}

extension GraphPageInfo {
    /// The zero value for pagination.
    static let zero = Self(
        hasPreviousPage: false,
        hasNextPage: false,
        startCursor: nil,
        endCursor: nil
    )
}
