import Cocoa

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let onCaptureSelection: () -> Void
    private let onCaptureFullScreen: () -> Void
    private let onCaptureWindow: () -> Void
    private let onPreferences: () -> Void
    private let onQuit: () -> Void

    init(
        onCaptureSelection: @escaping () -> Void,
        onCaptureFullScreen: @escaping () -> Void,
        onCaptureWindow: @escaping () -> Void,
        onPreferences: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onCaptureSelection = onCaptureSelection
        self.onCaptureFullScreen = onCaptureFullScreen
        self.onCaptureWindow = onCaptureWindow
        self.onPreferences = onPreferences
        self.onQuit = onQuit
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
    }

    func start() {
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "OpenShot") {
                button.image = image
                button.imagePosition = .imageOnly
            } else {
                button.title = "OpenShot"
            }
        } else {
            NSLog("Status item button unavailable")
        }
        statusItem.menu = buildMenu()
        NSLog("Menu bar item started")
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let selectionItem = NSMenuItem(
            title: "Capture Selection",
            action: #selector(captureSelection),
            keyEquivalent: "s"
        )
        selectionItem.target = self
        menu.addItem(selectionItem)

        let windowItem = NSMenuItem(
            title: "Capture Window",
            action: #selector(captureWindow),
            keyEquivalent: "w"
        )
        windowItem.target = self
        menu.addItem(windowItem)

        let fullScreenItem = NSMenuItem(
            title: "Capture Full Screen",
            action: #selector(captureFullScreen),
            keyEquivalent: "f"
        )
        fullScreenItem.target = self
        menu.addItem(fullScreenItem)

        menu.addItem(.separator())

        let preferencesItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        preferencesItem.target = self
        menu.addItem(preferencesItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit OpenShot",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func captureSelection() {
        onCaptureSelection()
    }

    @objc private func captureWindow() {
        onCaptureWindow()
    }

    @objc private func captureFullScreen() {
        onCaptureFullScreen()
    }

    @objc private func openPreferences() {
        onPreferences()
    }

    @objc private func quit() {
        onQuit()
    }
}
