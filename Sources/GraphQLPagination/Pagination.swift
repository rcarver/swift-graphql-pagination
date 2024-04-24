import Foundation

/// The interface describing forward pagination inputs.
public protocol GraphForwardPaginatable {
    var first: Int? { get }
    var after: Cursor? { get }
}

/// The interface describing backward pagination inputs.
public protocol GraphBackwardPaginatable {
    var last: Int? { get }
    var before: Cursor? { get }
}

/// The interface describing pagination inputs.
public protocol GraphPaginatable: GraphForwardPaginatable, GraphBackwardPaginatable {}

extension GraphForwardPaginatable {
    /// Construct the real pagination from available inputs.
    public var current: GraphPagination? {
        if self.first != nil || self.after != nil {
            return .forward(.init(first: self.first, after: self.after))
        }
        return nil
    }
}

extension GraphPaginatable {
    /// Construct the real pagination from available inputs.
    public var current: GraphPagination? {
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
public enum GraphPagination {
    case forward(GraphForwardPagination)
    case backward(GraphBackwardPagination)
}

/// A concrete forward pagination input.
public struct GraphForwardPagination: GraphForwardPaginatable {
    public var first: Int?
    public var after: Cursor?
    public init(first: Int? = nil, after: Cursor? = nil) {
        self.first = first
        self.after = after
    }
}

/// A concrete backward pagination input.
public struct GraphBackwardPagination: GraphBackwardPaginatable {
    public var last: Int?
    public var before: Cursor?
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
    public init(
        hasPreviousPage: Bool,
        hasNextPage: Bool,
        startCursor: Cursor?,
        endCursor: Cursor?
    ) {
        self.hasPreviousPage = hasPreviousPage
        self.hasNextPage = hasNextPage
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}

extension GraphPageInfo {
    /// The zero value for pagination.
    public static let zero = Self(
        hasPreviousPage: false,
        hasNextPage: false,
        startCursor: nil,
        endCursor: nil
    )
}
