import AppKit
@testable import OneShot
import XCTest

final class HotkeyTests: XCTestCase {
    func testNormalizedModifiersDropUnsupportedFlags() {
        let hotkey = Hotkey(keyCode: 6, modifiers: [.command, .shift, .capsLock, .function])

        XCTAssertTrue(hotkey.modifiers.contains(.command))
        XCTAssertTrue(hotkey.modifiers.contains(.shift))
        XCTAssertFalse(hotkey.modifiers.contains(.capsLock))
        XCTAssertFalse(hotkey.modifiers.contains(.function))
    }

    func testDecodingNormalizesModifiers() throws {
        let rawValue = NSEvent.ModifierFlags.shift.rawValue | NSEvent.ModifierFlags.capsLock.rawValue
        let json = "{\"keyCode\":6,\"modifiers\":\(rawValue)}"

        let hotkey = try JSONDecoder().decode(Hotkey.self, from: Data(json.utf8))

        XCTAssertEqual(hotkey.keyCode, 6)
        XCTAssertTrue(hotkey.modifiers.contains(.shift))
        XCTAssertFalse(hotkey.modifiers.contains(.capsLock))
    }
}
