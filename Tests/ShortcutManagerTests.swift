import Carbon.HIToolbox
@testable import OneShot
import XCTest

final class ShortcutManagerTests: XCTestCase {
    @MainActor
    func testApplyWhenDisabledMarksShortcutsDisabled() {
        let registrar = HotkeyRegistrarStub()
        let manager = ShortcutManager(
            hotkeyRegistrar: registrar,
            onCaptureFullScreen: {},
            onCaptureSelection: {},
            onShowCaptureHUD: {}
        )
        let bindings = ScreenshotShortcutBindings(
            fullScreen: "cmd+shift+3",
            selection: "cmd+shift+4",
            captureHUD: "cmd+shift+5"
        )

        manager.apply(bindings: bindings, isEnabled: false)

        XCTAssertEqual(manager.statuses.count, ScreenshotShortcut.allCases.count)
        XCTAssertTrue(manager.statuses.allSatisfy { status in
            if case .disabled = status.state {
                return true
            }
            return false
        })
        XCTAssertFalse(manager.hasConflicts)
        XCTAssertEqual(registrar.unregisterCount, 1)
    }

    @MainActor
    func testApplyReportsInvalidBindings() {
        let registrar = HotkeyRegistrarStub()
        let manager = ShortcutManager(
            hotkeyRegistrar: registrar,
            onCaptureFullScreen: {},
            onCaptureSelection: {},
            onShowCaptureHUD: {}
        )
        let bindings = ScreenshotShortcutBindings(
            fullScreen: "cmd+shift+3",
            selection: "invalid",
            captureHUD: "cmd+shift+5"
        )

        manager.apply(bindings: bindings, isEnabled: true)

        let selectionStatus = manager.statuses.first { $0.shortcut == .selection }
        XCTAssertEqual(selectionStatus?.state, .invalidBinding)
        XCTAssertFalse(manager.hasConflicts)
    }

    @MainActor
    func testApplyMarksFailedRegistrationsAsConflicts() {
        let registrar = HotkeyRegistrarStub()
        registrar.statuses["cmd+shift+3"] = eventHotKeyExistsErr
        let manager = ShortcutManager(
            hotkeyRegistrar: registrar,
            onCaptureFullScreen: {},
            onCaptureSelection: {},
            onShowCaptureHUD: {}
        )
        let bindings = ScreenshotShortcutBindings(
            fullScreen: "cmd+shift+3",
            selection: "cmd+shift+4",
            captureHUD: "cmd+shift+5"
        )

        manager.apply(bindings: bindings, isEnabled: true)

        let fullScreenStatus = manager.statuses.first { $0.shortcut == .fullScreen }
        if case let .failed(status)? = fullScreenStatus?.state {
            XCTAssertEqual(status, eventHotKeyExistsErr)
        } else {
            XCTFail("Expected failed status for full screen hotkey")
        }
        XCTAssertTrue(manager.hasConflicts)
    }
}

private final class HotkeyRegistrarStub: HotkeyRegistering {
    var statuses: [String: OSStatus] = [:]
    private(set) var unregisterCount = 0

    @discardableResult
    func register(hotkey: Hotkey, handler _: @escaping () -> Void) -> OSStatus {
        statuses[hotkey.display] ?? noErr
    }

    func unregisterAll() {
        unregisterCount += 1
    }
}
