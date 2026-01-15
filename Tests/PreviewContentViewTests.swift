import AppKit
@testable import OneShot
import XCTest

final class PreviewContentViewTests: XCTestCase {
    func testLayoutUsesFullSizeImageWithOverlayButtons() {
        let view = PreviewContentView(frame: NSRect(x: 0, y: 0, width: 200, height: 120))
        view.layout()

        guard let backgroundView = view.subviews.first(
            where: { $0 is NSVisualEffectView },
        ) as? NSVisualEffectView else {
            XCTFail("Missing background view")
            return
        }

        guard let imageView = backgroundView.subviews.compactMap({ $0 as? PreviewImageView }).first else {
            XCTFail("Missing preview image view")
            return
        }

        guard let overlayView = view.subviews.first(
            where: { $0 is PreviewActionOverlayView },
        ) as? PreviewActionOverlayView else {
            XCTFail("Missing action overlay view")
            return
        }

        let buttons = overlayView.subviews.compactMap { $0 as? NSButton }
        guard let closeButton = buttons.first(where: { $0.identifier?.rawValue == "preview-close" }) else {
            XCTFail("Missing close button")
            return
        }
        guard let trashButton = buttons.first(where: { $0.identifier?.rawValue == "preview-trash" }) else {
            XCTFail("Missing trash button")
            return
        }

        XCTAssertEqual(imageView.frame, backgroundView.bounds)
        XCTAssertEqual(overlayView.frame, view.bounds)
        XCTAssertTrue(overlayView.isHidden)
        XCTAssertTrue(backgroundView.frame.minX > view.bounds.minX)
        XCTAssertTrue(backgroundView.frame.minY > view.bounds.minY)
        XCTAssertTrue(backgroundView.frame.maxX < view.bounds.maxX)
        XCTAssertTrue(backgroundView.frame.maxY < view.bounds.maxY)

        XCTAssertEqual(closeButton.frame.width, closeButton.frame.height, accuracy: 0.5)
        XCTAssertEqual(closeButton.frame.width, trashButton.frame.width, accuracy: 0.5)
        XCTAssertEqual(closeButton.frame.minY, trashButton.frame.minY, accuracy: 0.5)
        XCTAssertEqual(closeButton.frame.minX, view.bounds.minX, accuracy: 0.5)
        XCTAssertEqual(trashButton.frame.maxX, view.bounds.maxX, accuracy: 0.5)
        XCTAssertEqual(closeButton.frame.maxY, view.bounds.maxY, accuracy: 0.5)
        XCTAssertTrue(closeButton.frame.minX < backgroundView.frame.minX)
        XCTAssertTrue(trashButton.frame.maxX > backgroundView.frame.maxX)
        XCTAssertTrue(closeButton.frame.maxY > backgroundView.frame.maxY)
    }

    func testHitTestPrefersButtonsOverImage() {
        let view = PreviewContentView(frame: NSRect(x: 0, y: 0, width: 200, height: 120))
        view.layout()

        guard let backgroundView = view.subviews.first(
            where: { $0 is NSVisualEffectView },
        ) as? NSVisualEffectView else {
            XCTFail("Missing background view")
            return
        }

        guard let imageView = backgroundView.subviews.compactMap({ $0 as? PreviewImageView }).first else {
            XCTFail("Missing preview image view")
            return
        }

        guard let overlayView = view.subviews.first(
            where: { $0 is PreviewActionOverlayView },
        ) as? PreviewActionOverlayView else {
            XCTFail("Missing action overlay view")
            return
        }

        let buttons = overlayView.subviews.compactMap { $0 as? NSButton }
        guard let closeButton = buttons.first(where: { $0.identifier?.rawValue == "preview-close" }) else {
            XCTFail("Missing close button")
            return
        }
        guard let trashButton = buttons.first(where: { $0.identifier?.rawValue == "preview-trash" }) else {
            XCTFail("Missing trash button")
            return
        }

        view.setActionsVisibleForTesting(true)
        view.layout()

        let closeFrame = closeButton.convert(closeButton.bounds, to: view)
        let closePoint = NSPoint(x: closeFrame.midX, y: closeFrame.midY)
        let hitClose = view.hitTest(closePoint)
        XCTAssertEqual(hitClose?.identifier?.rawValue, "preview-close")

        let trashFrame = trashButton.convert(trashButton.bounds, to: view)
        let trashPoint = NSPoint(x: trashFrame.midX, y: trashFrame.midY)
        let hitTrash = view.hitTest(trashPoint)
        XCTAssertEqual(hitTrash?.identifier?.rawValue, "preview-trash")

        let imageFrame = imageView.convert(imageView.bounds, to: view)
        let imagePoint = NSPoint(x: imageFrame.midX, y: imageFrame.midY)
        let hitImage = view.hitTest(imagePoint)
        XCTAssertTrue(hitImage is PreviewImageView)
    }
}
