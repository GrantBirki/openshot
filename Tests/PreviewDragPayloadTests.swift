import AppKit
import XCTest
@testable import OneShot

final class PreviewDragPayloadTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "oneshot-preview-drag-tests-\(UUID().uuidString)",
            isDirectory: true
        )
    }

    override func tearDown() {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
        super.tearDown()
    }

    func testPasteboardItemIncludesFileURLAndImageTypes() throws {
        let cgImage = makeCGImage(width: 1, height: 1)
        let image = NSImage(cgImage: cgImage, size: NSSize(width: 1, height: 1))
        let pngData = try PNGDataEncoder.encode(cgImage: cgImage)

        let payload = PreviewDragPayload(
            image: image,
            pngData: pngData,
            filenamePrefix: "screenshot",
            baseDirectory: tempDirectory,
            cleanupDelay: 60
        )

        guard let item = payload.makePasteboardItem() else {
            XCTFail("Expected pasteboard item to be created")
            return
        }

        guard let fileURLString = item.string(forType: .fileURL),
              let fileURL = URL(string: fileURLString) else {
            XCTFail("Expected file URL on pasteboard item")
            return
        }

        XCTAssertTrue(fileURL.path.hasPrefix(tempDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(item.data(forType: .png), pngData)
        XCTAssertNotNil(item.data(forType: .tiff))
        XCTAssertTrue(item.types.contains(.fileURL))
        XCTAssertTrue(item.types.contains(.png))
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
