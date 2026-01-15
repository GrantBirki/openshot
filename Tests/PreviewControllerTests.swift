import AppKit
import XCTest
@testable import OneShot

final class PreviewControllerTests: XCTestCase {
    @MainActor
    func testShowReplacesExistingPreviewByFinalizing() throws {
        let controller = PreviewController()
        let cgImage = makeCGImage(width: 1, height: 1)
        let image = NSImage(cgImage: cgImage, size: NSSize(width: 1, height: 1))
        let pngData = try PNGDataEncoder.encode(cgImage: cgImage)

        var closeCount = 0
        controller.show(
            image: image,
            pngData: pngData,
            filenamePrefix: "screenshot",
            timeout: nil,
            onClose: { closeCount += 1 },
            onTrash: {},
            onAutoDismiss: nil,
            anchorRect: nil
        )

        controller.show(
            image: image,
            pngData: pngData,
            filenamePrefix: "screenshot",
            timeout: nil,
            onClose: {},
            onTrash: {},
            onAutoDismiss: nil,
            anchorRect: nil
        )

        XCTAssertEqual(closeCount, 1)
        controller.hide()
    }

    private func makeCGImage(width: Int, height: Int) -> CGImage {
        makeBitmapRep(width: width, height: height).cgImage!
    }

    private func makeBitmapRep(width: Int, height: Int) -> NSBitmapImageRep {
        NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
    }
}
