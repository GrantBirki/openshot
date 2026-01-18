import AppKit
import CoreGraphics
@testable import OneShot
import XCTest

final class SelectionOverlayStateTests: XCTestCase {
    func testSelectionSizeTextRoundsAndFormats() {
        let state = SelectionOverlayState(
            showSelectionCoordinates: true,
            dimmingMode: .fullScreen,
            selectionDimmingColor: .black,
        )
        state.start = CGPoint(x: 10.2, y: 20.6)
        state.current = CGPoint(x: 30.6, y: 50.2)

        XCTAssertEqual(state.selectionSizeText, "20 x 30")
    }

    func testSelectionSizeTextHandlesReverseDrag() {
        let state = SelectionOverlayState(
            showSelectionCoordinates: true,
            dimmingMode: .fullScreen,
            selectionDimmingColor: .black,
        )
        state.start = CGPoint(x: 80, y: 120)
        state.current = CGPoint(x: 30, y: 50)

        XCTAssertEqual(state.selectionSizeText, "50 x 70")
    }

    func testSelectionSizeTextNilWithoutPoints() {
        let state = SelectionOverlayState(
            showSelectionCoordinates: true,
            dimmingMode: .fullScreen,
            selectionDimmingColor: .black,
        )

        XCTAssertNil(state.selectionSizeText)
        state.start = CGPoint(x: 10, y: 10)
        XCTAssertNil(state.selectionSizeText)
        state.start = nil
        state.current = CGPoint(x: 10, y: 10)
        XCTAssertNil(state.selectionSizeText)
    }

    func testSelectionSizeTextHiddenWhenDisabled() {
        let state = SelectionOverlayState(
            showSelectionCoordinates: false,
            dimmingMode: .fullScreen,
            selectionDimmingColor: .black,
        )
        state.start = CGPoint(x: 10, y: 20)
        state.current = CGPoint(x: 30, y: 50)

        XCTAssertNil(state.selectionSizeText)
    }

    func testRectCalculatesBoundsFromStartAndCurrent() {
        let state = SelectionOverlayState(
            showSelectionCoordinates: true,
            dimmingMode: .fullScreen,
            selectionDimmingColor: .black,
        )
        state.start = CGPoint(x: 80, y: 20)
        state.current = CGPoint(x: 30, y: 70)

        XCTAssertEqual(state.rect, CGRect(x: 30, y: 20, width: 50, height: 50))
    }

    func testRectAllowsZeroSizedSelection() {
        let state = SelectionOverlayState(
            showSelectionCoordinates: true,
            dimmingMode: .fullScreen,
            selectionDimmingColor: .black,
        )
        state.start = CGPoint(x: 10, y: 10)
        state.current = CGPoint(x: 10, y: 10)

        XCTAssertEqual(state.rect, CGRect(x: 10, y: 10, width: 0, height: 0))
    }
}
