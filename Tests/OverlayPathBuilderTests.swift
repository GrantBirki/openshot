import CoreGraphics
@testable import OneShot
import XCTest

final class OverlayPathBuilderTests: XCTestCase {
    func testDimmingPathWithoutCutoutCoversBounds() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        let path = OverlayPathBuilder.dimmingPath(bounds: bounds, cutout: nil)

        XCTAssertTrue(path.contains(CGPoint(x: 10, y: 10), using: .evenOdd, transform: .identity))
        XCTAssertFalse(path.contains(CGPoint(x: -1, y: -1), using: .evenOdd, transform: .identity))
    }

    func testDimmingPathWithCutoutExcludesCutout() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        let cutout = CGRect(x: 25, y: 25, width: 50, height: 50)
        let path = OverlayPathBuilder.dimmingPath(bounds: bounds, cutout: cutout)

        XCTAssertTrue(path.contains(CGPoint(x: 10, y: 10), using: .evenOdd, transform: .identity))
        XCTAssertFalse(path.contains(CGPoint(x: 50, y: 50), using: .evenOdd, transform: .identity))
    }
}
