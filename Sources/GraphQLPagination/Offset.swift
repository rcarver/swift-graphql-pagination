import Foundation

/// Traditional offset pagination, describing the offset of
/// the first record, and the number of records to return.
public struct OffsetPagination: Equatable, Sendable {
    public var offset: Int
    public var count: Int?
    public init(offset: Int = 0, count: Int? = nil) {
        self.offset = offset
        self.count = count
    }
}

extension GraphPagination {
    /// Convert graph pagination to offset pagination.
    public func makeOffsetPagination() -> OffsetPagination {
        switch self {
        case let .forward(forward): forward.makeOffsetPagination()
        case let .backward(backward): backward.makeOffsetPagination()
        }
    }
}

extension GraphPaginatable {
    /// Convert bi-directional graph pagination to offset pagination.
    public func makeOffsetPagination() -> OffsetPagination {
        self.pagination?.makeOffsetPagination() ?? OffsetPagination()
    }
}

extension GraphForwardPaginatable {
    /// Convert forward graph pagination to offset pagination.
    public func makeOffsetPagination() -> OffsetPagination {
        switch (self.after?.intValue(), self.first) {
        case let (.some(after), .some(first)):
            return OffsetPagination(offset: after, count: first + 2)
        case let (.some(after), .none):
            return OffsetPagination(offset: after, count: nil)
        case let (.none, .some(first)):
            return OffsetPagination(offset: 0, count: first + 1)
        case (.none, .none):
            return OffsetPagination(offset: 0, count: nil)
        }
    }
}

extension GraphBackwardPaginatable {
    /// Convert backward graph pagination to offset pagination.
    public func makeOffsetPagination() -> OffsetPagination {
        switch (self.before?.intValue(), self.last) {
        case let (.some(before), .some(last)):
            return OffsetPagination(offset: max(0, before - last - 1), count: last + 2)
        case let (.some(before), .none):
            return OffsetPagination(offset: 0, count: before + 1)
        case let (.none, .some(last)):
            return OffsetPagination(offset: 0, count: last + 1)
        case (.none, .none):
            return OffsetPagination(offset: 0, count: nil)
        }
    }
}
