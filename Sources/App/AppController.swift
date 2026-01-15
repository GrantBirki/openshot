import Cocoa
import Combine

final class AppController {
    private let settings: SettingsStore
    private let captureManager: CaptureManager
    private let shortcutManager: ShortcutManager
    private let menuBarController: MenuBarController
    private let settingsWindowController: SettingsWindowController
    private let launchAtLoginManager: LaunchAtLoginManager
    private var cancellables = Set<AnyCancellable>()

    init() {
        settings = SettingsStore()
        captureManager = CaptureManager(settings: settings)
        shortcutManager = ShortcutManager(
            onCaptureFullScreen: { [weak captureManager] in captureManager?.captureFullScreen() },
            onCaptureSelection: { [weak captureManager] in captureManager?.captureSelection() },
            onShowCaptureHUD: { [weak captureManager] in captureManager?.showCaptureHUD() }
        )
        settingsWindowController = SettingsWindowController(settings: settings, shortcutManager: shortcutManager)
        launchAtLoginManager = LaunchAtLoginManager()

        menuBarController = MenuBarController(
            onCaptureSelection: { [weak captureManager] in captureManager?.captureSelection() },
            onCaptureFullScreen: { [weak captureManager] in captureManager?.captureFullScreen() },
            onCaptureWindow: { [weak captureManager] in captureManager?.captureWindow() },
            onShowCaptureHUD: { [weak captureManager] in captureManager?.showCaptureHUD() },
            onSettings: { [weak settingsWindowController] in settingsWindowController?.show() },
            onQuit: { NSApp.terminate(nil) },
            hotkeyProvider: { [weak settings] in
                guard let settings = settings, settings.screenshotShortcutsEnabled else {
                    return MenuBarHotkeys(selection: "", fullScreen: "", captureHUD: "")
                }
                return MenuBarHotkeys(
                    selection: settings.hotkeySelection,
                    fullScreen: settings.hotkeyFullScreen,
                    captureHUD: settings.hotkeyCaptureHUD
                )
            }
        )
    }

    func start() {
        NSLog("OneShot AppController start")
        menuBarController.start()
        applyShortcutSettings()
        observeSettings()
        launchAtLoginManager.setEnabled(settings.autoLaunchEnabled)
    }

    private func observeSettings() {
        settings.$autoLaunchEnabled
            .sink { [weak self] enabled in
                self?.launchAtLoginManager.setEnabled(enabled)
            }
            .store(in: &cancellables)

        settings.$screenshotShortcutsEnabled
            .sink { [weak self] _ in self?.applyShortcutSettings() }
            .store(in: &cancellables)
        settings.$hotkeySelection
            .sink { [weak self] _ in self?.applyShortcutSettings() }
            .store(in: &cancellables)
        settings.$hotkeyFullScreen
            .sink { [weak self] _ in self?.applyShortcutSettings() }
            .store(in: &cancellables)
        settings.$hotkeyCaptureHUD
            .sink { [weak self] _ in self?.applyShortcutSettings() }
            .store(in: &cancellables)
    }

    private func applyShortcutSettings() {
        let bindings = ScreenshotShortcutBindings(
            fullScreen: settings.hotkeyFullScreen,
            selection: settings.hotkeySelection,
            captureHUD: settings.hotkeyCaptureHUD
        )
        shortcutManager.apply(bindings: bindings, isEnabled: settings.screenshotShortcutsEnabled)
        menuBarController.refreshHotkeys()
    }
}
