import Cocoa
import Combine

final class AppController {
    private let settings: SettingsStore
    private let hotkeyManager: HotkeyManager
    private let captureManager: CaptureManager
    private let menuBarController: MenuBarController
    private let preferencesWindowController: PreferencesWindowController
    private let launchAtLoginManager: LaunchAtLoginManager
    private var cancellables = Set<AnyCancellable>()

    init() {
        settings = SettingsStore()
        hotkeyManager = HotkeyManager()
        captureManager = CaptureManager(settings: settings)
        preferencesWindowController = PreferencesWindowController(settings: settings)
        launchAtLoginManager = LaunchAtLoginManager()

        menuBarController = MenuBarController(
            onCaptureSelection: { [weak captureManager] in captureManager?.captureSelection() },
            onCaptureFullScreen: { [weak captureManager] in captureManager?.captureFullScreen() },
            onCaptureWindow: { [weak captureManager] in captureManager?.captureWindow() },
            onPreferences: { [weak preferencesWindowController] in preferencesWindowController?.show() },
            onQuit: { NSApp.terminate(nil) }
        )
    }

    func start() {
        menuBarController.start()
        registerHotkeys()
        observeSettings()
        launchAtLoginManager.setEnabled(settings.autoLaunchEnabled)
    }

    private func observeSettings() {
        settings.$autoLaunchEnabled
            .sink { [weak self] enabled in
                self?.launchAtLoginManager.setEnabled(enabled)
            }
            .store(in: &cancellables)

        settings.$hotkeySelection
            .sink { [weak self] _ in self?.registerHotkeys() }
            .store(in: &cancellables)
        settings.$hotkeyFullScreen
            .sink { [weak self] _ in self?.registerHotkeys() }
            .store(in: &cancellables)
        settings.$hotkeyWindow
            .sink { [weak self] _ in self?.registerHotkeys() }
            .store(in: &cancellables)
    }

    private func registerHotkeys() {
        hotkeyManager.unregisterAll()

        if let selectionHotkey = HotkeyParser.parse(settings.hotkeySelection) {
            hotkeyManager.register(hotkey: selectionHotkey) { [weak self] in
                self?.captureManager.captureSelection()
            }
        }

        if let fullScreenHotkey = HotkeyParser.parse(settings.hotkeyFullScreen) {
            hotkeyManager.register(hotkey: fullScreenHotkey) { [weak self] in
                self?.captureManager.captureFullScreen()
            }
        }

        if let windowHotkey = HotkeyParser.parse(settings.hotkeyWindow) {
            hotkeyManager.register(hotkey: windowHotkey) { [weak self] in
                self?.captureManager.captureWindow()
            }
        }
    }
}
