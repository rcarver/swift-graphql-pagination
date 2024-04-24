import CustomDump
import XCTest

@testable import GraphQLPagination

final class OffsetTests: XCTestCase {

    struct Forward: GraphForwardPaginatable {
        var first: Int?
        var after: Cursor?
    }

    struct Backward: GraphBackwardPaginatable {
        var before: Cursor?
        var last: Int?
    }

    func test_forward() {
        XCTAssertNoDifference(
            Forward(first: nil, after: nil).makeOffsetPagination(),
            OffsetPagination(offset: nil, count: nil)
        )
        XCTAssertNoDifference(
            Forward(first: 10, after: nil).makeOffsetPagination(),
            OffsetPagination(offset: nil, count: 12)
        )
        XCTAssertNoDifference(
            Forward(first: 10, after: Cursor(intValue: 3)).makeOffsetPagination(),
            OffsetPagination(offset: 3, count: 12)
        )
        XCTAssertNoDifference(
            Forward(first: nil, after: Cursor(intValue: 3)).makeOffsetPagination(),
            OffsetPagination(offset: 3, count: nil)
        )
    }

    func test_backward() {
        XCTAssertNoDifference(
            Backward(before: nil, last: nil).makeOffsetPagination(),
            OffsetPagination(offset: nil, count: nil)
        )
        XCTAssertNoDifference(
            Backward(before: nil, last: 10).makeOffsetPagination(),
            OffsetPagination(offset: nil, count: 12)
        )
        XCTAssertNoDifference(
            Backward(before: Cursor(intValue: 10), last: 3).makeOffsetPagination(),
            OffsetPagination(offset: 6, count: 5)
        )
        XCTAssertNoDifference(
            Backward(before: Cursor(intValue: 10), last: nil).makeOffsetPagination(),
            OffsetPagination(offset: 0, count: 11)
        )
    }
}
