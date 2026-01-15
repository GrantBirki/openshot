@testable import OneShot
import XCTest

final class SettingsStoreTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "SettingsStoreTests")
        defaults.removePersistentDomain(forName: "SettingsStoreTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "SettingsStoreTests")
        defaults = nil
        super.tearDown()
    }

    func testDefaultsAreApplied() {
        let settings = SettingsStore(defaults: defaults)
        XCTAssertFalse(settings.autoLaunchEnabled)
        XCTAssertEqual(settings.saveDelaySeconds, 7)
        XCTAssertTrue(settings.previewTimeoutEnabled)
        XCTAssertEqual(settings.previewTimeout, 7)
        XCTAssertTrue(settings.previewEnabled)
        XCTAssertEqual(settings.previewReplacementBehavior, .saveImmediately)
        XCTAssertTrue(settings.screenshotShortcutsEnabled)
        XCTAssertEqual(settings.saveLocationOption, .downloads)
        XCTAssertEqual(settings.filenamePrefix, "screenshot")
        XCTAssertEqual(settings.hotkeySelection, "cmd+shift+4")
        XCTAssertEqual(settings.hotkeyFullScreen, "cmd+shift+3")
        XCTAssertEqual(settings.hotkeyCaptureHUD, "cmd+shift+5")
    }

    func testValuesPersistToDefaults() {
        var settings = SettingsStore(defaults: defaults)
        settings.autoLaunchEnabled = true
        settings.saveDelaySeconds = 3
        settings.previewTimeoutEnabled = false
        settings.previewEnabled = false
        settings.previewReplacementBehavior = .discard
        settings.screenshotShortcutsEnabled = false
        settings.saveLocationOption = .desktop
        settings.customSavePath = "/tmp"
        settings.filenamePrefix = "grab"
        settings.hotkeySelection = "ctrl+z"
        settings.hotkeyFullScreen = "ctrl+shift+z"
        settings.hotkeyCaptureHUD = "ctrl+shift+5"

        settings = SettingsStore(defaults: defaults)
        XCTAssertTrue(settings.autoLaunchEnabled)
        XCTAssertEqual(settings.saveDelaySeconds, 3)
        XCTAssertFalse(settings.previewTimeoutEnabled)
        XCTAssertNil(settings.previewTimeout)
        XCTAssertFalse(settings.previewEnabled)
        XCTAssertEqual(settings.previewReplacementBehavior, .discard)
        XCTAssertFalse(settings.screenshotShortcutsEnabled)
        XCTAssertEqual(settings.saveLocationOption, .desktop)
        XCTAssertEqual(settings.customSavePath, "/tmp")
        XCTAssertEqual(settings.filenamePrefix, "grab")
        XCTAssertEqual(settings.hotkeySelection, "ctrl+z")
        XCTAssertEqual(settings.hotkeyFullScreen, "ctrl+shift+z")
        XCTAssertEqual(settings.hotkeyCaptureHUD, "ctrl+shift+5")
    }

    func testPreviewTimeoutUsesSaveDelay() {
        let settings = SettingsStore(defaults: defaults)
        settings.saveDelaySeconds = 5
        settings.previewTimeoutEnabled = true
        XCTAssertEqual(settings.previewTimeout, 5)
    }
}
