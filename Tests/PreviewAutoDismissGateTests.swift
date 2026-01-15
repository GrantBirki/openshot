@testable import OneShot
import XCTest

final class PreviewAutoDismissGateTests: XCTestCase {
    func testDeadlineReachedDismissesWhenNotInteracting() {
        let deadline = Date(timeIntervalSince1970: 10)
        var gate = PreviewAutoDismissGate(deadline: deadline)

        XCTAssertTrue(gate.deadlineReached(now: Date(timeIntervalSince1970: 11)))
        XCTAssertFalse(gate.pending)
    }

    func testDeadlineReachedDefersWhileHoveredThenDismissesOnHoverExit() {
        let deadline = Date(timeIntervalSince1970: 10)
        var gate = PreviewAutoDismissGate(deadline: deadline)
        gate.isHovered = true

        XCTAssertFalse(gate.deadlineReached(now: Date(timeIntervalSince1970: 10)))
        XCTAssertTrue(gate.pending)

        XCTAssertTrue(gate.interactionChanged(isHovered: false, now: Date(timeIntervalSince1970: 12)))
        XCTAssertTrue(gate.pending)
        XCTAssertTrue(gate.deadlineReached(now: Date(timeIntervalSince1970: 12)))
        XCTAssertFalse(gate.pending)
    }

    func testDeadlineReachedDefersWhileDraggingThenDismissesOnDragEnd() {
        let deadline = Date(timeIntervalSince1970: 10)
        var gate = PreviewAutoDismissGate(deadline: deadline)
        gate.isDragging = true

        XCTAssertFalse(gate.deadlineReached(now: Date(timeIntervalSince1970: 10)))
        XCTAssertTrue(gate.pending)

        XCTAssertTrue(gate.interactionChanged(isDragging: false, now: Date(timeIntervalSince1970: 12)))
        XCTAssertTrue(gate.pending)
        XCTAssertTrue(gate.deadlineReached(now: Date(timeIntervalSince1970: 12)))
        XCTAssertFalse(gate.pending)
    }
}
