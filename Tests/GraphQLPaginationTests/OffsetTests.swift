import CustomDump
import XCTest

@testable import GraphQLPagination

final class OffsetTests: XCTestCase {

    typealias Forward = GraphForwardPagination
    typealias Backward = GraphBackwardPagination

    func test_forward() {
        XCTAssertNoDifference(
            Forward(first: nil, after: nil).makeOffsetPagination(),
            OffsetPagination(offset: 0, count: nil)
        )
        XCTAssertNoDifference(
            Forward(first: 10, after: nil).makeOffsetPagination(),
            OffsetPagination(offset: 0, count: 11)
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
    func test_forward_invalid() {
        XCTAssertNoDifference(
            Forward(first: 10, after: Cursor(rawValue: "a")).makeOffsetPagination(),
            OffsetPagination(offset: 0, count: 11)
        )
    }

    func test_backward() {
        XCTAssertNoDifference(
            Backward(last: nil, before: nil).makeOffsetPagination(),
            OffsetPagination(offset: 0, count: nil)
        )
        XCTAssertNoDifference(
            Backward(last: 10, before: nil).makeOffsetPagination(),
            OffsetPagination(offset: 0, count: 11)
        )
        XCTAssertNoDifference(
            Backward(last: 3, before: Cursor(intValue: 10)).makeOffsetPagination(),
            OffsetPagination(offset: 6, count: 5)
        )
        XCTAssertNoDifference(
            Backward(last: nil, before: Cursor(intValue: 10)).makeOffsetPagination(),
            OffsetPagination(offset: 0, count: 11)
        )
    }
    func test_backward_invalid() {
        XCTAssertNoDifference(
            Backward(last: 10, before: Cursor(rawValue: "a")).makeOffsetPagination(),
            OffsetPagination(offset: 0, count: 11)
        )
        XCTAssertNoDifference(
            Backward(last: 10, before: Cursor(intValue: 5)).makeOffsetPagination(),
            OffsetPagination(offset: 0, count: 12)
        )
    }
}
