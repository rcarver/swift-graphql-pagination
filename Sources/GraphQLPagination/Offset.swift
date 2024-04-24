import Foundation

public struct OffsetPagination: Equatable {
    public var offset: Int?
    public var count: Int?
    public init(offset: Int? = nil, count: Int? = nil) {
        self.offset = offset
        self.count = count
    }
}

extension GraphPaginatable {
    func makeOffsetPagination() -> OffsetPagination {
        switch self.current {
        case let .forward(forward): forward.makeOffsetPagination()
        case let .backward(backward): backward.makeOffsetPagination()
        case .none: OffsetPagination()
        }
    }
}

extension GraphForwardPaginatable {
    /// Convert graph pagination to search pagination.
    func makeOffsetPagination() -> OffsetPagination {
        switch (self.after?.intValue(), self.first) {
        case let (.some(after), .some(first)):
            return OffsetPagination(offset: after, count: first + 2)
        case let (.some(after), .none):
            return OffsetPagination(offset: after, count: nil)
        case let (.none, .some(first)):
            return OffsetPagination(offset: nil, count: first + 2)
        case (.none, .none):
            return OffsetPagination(offset: nil, count: nil)
        }
    }
}

extension GraphBackwardPaginatable {
    /// Convert graph pagination to search pagination.
    func makeOffsetPagination() -> OffsetPagination {
        switch (self.before?.intValue(), self.last) {
        case let (.some(before), .some(last)):
            return OffsetPagination(offset: before - last - 1, count: last + 2)
        case let (.some(before), .none):
            return OffsetPagination(offset: 0, count: before + 1)
        case let (.none, .some(last)):
            return OffsetPagination(offset: nil, count: last + 2)
        case (.none, .none):
            return OffsetPagination(offset: nil, count: nil)
        }
    }
}
