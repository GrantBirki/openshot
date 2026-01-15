import Carbon.HIToolbox
import Combine
import Foundation

enum ScreenshotShortcut: String, CaseIterable, Identifiable {
    case fullScreen
    case selection
    case captureHUD

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullScreen:
            return "Full screen"
        case .selection:
            return "Selection"
        case .captureHUD:
            return "Capture toolbar"
        }
    }
}

struct ScreenshotShortcutBindings {
    let fullScreen: String
    let selection: String
    let captureHUD: String

    func binding(for shortcut: ScreenshotShortcut) -> String {
        switch shortcut {
        case .fullScreen:
            return fullScreen
        case .selection:
            return selection
        case .captureHUD:
            return captureHUD
        }
    }
}

enum ShortcutRegistrationState: Equatable {
    case registered
    case disabled
    case invalidBinding
    case failed(OSStatus)
}

enum ShortcutStatusStyle {
    case active
    case inactive
    case warning
}

struct ShortcutStatus: Identifiable, Equatable {
    let shortcut: ScreenshotShortcut
    let binding: String
    let state: ShortcutRegistrationState

    var id: String { shortcut.id }

    var title: String { shortcut.title }

    var label: String {
        switch state {
        case .registered:
            return "Active"
        case .disabled:
            return "Disabled"
        case .invalidBinding:
            return "Invalid"
        case let .failed(status):
            return status == eventHotKeyExistsErr ? "In use by macOS" : "Unavailable"
        }
    }

    var style: ShortcutStatusStyle {
        switch state {
        case .registered:
            return .active
        case .disabled:
            return .inactive
        case .invalidBinding, .failed:
            return .warning
        }
    }
}

@MainActor
final class ShortcutManager: ObservableObject {
    @Published private(set) var statuses: [ShortcutStatus] = []
    @Published private(set) var hasConflicts = false

    private let hotkeyRegistrar: HotkeyRegistering
    private let onCaptureFullScreen: () -> Void
    private let onCaptureSelection: () -> Void
    private let onShowCaptureHUD: () -> Void

    init(
        hotkeyRegistrar: HotkeyRegistering = HotkeyManager(),
        onCaptureFullScreen: @escaping () -> Void,
        onCaptureSelection: @escaping () -> Void,
        onShowCaptureHUD: @escaping () -> Void
    ) {
        self.hotkeyRegistrar = hotkeyRegistrar
        self.onCaptureFullScreen = onCaptureFullScreen
        self.onCaptureSelection = onCaptureSelection
        self.onShowCaptureHUD = onShowCaptureHUD
    }

    func apply(bindings: ScreenshotShortcutBindings, isEnabled: Bool) {
        hotkeyRegistrar.unregisterAll()
        statuses = ScreenshotShortcut.allCases.map { shortcut in
            let binding = bindings.binding(for: shortcut)
            if !isEnabled {
                return ShortcutStatus(shortcut: shortcut, binding: binding, state: .disabled)
            }

            guard let hotkey = HotkeyParser.parse(binding) else {
                return ShortcutStatus(shortcut: shortcut, binding: binding, state: .invalidBinding)
            }

            // macOS may reserve these shortcuts; a failed registration is surfaced so the UI can guide the user.
            let status = hotkeyRegistrar.register(hotkey: hotkey, handler: handler(for: shortcut))
            if status == noErr {
                return ShortcutStatus(shortcut: shortcut, binding: binding, state: .registered)
            }

            return ShortcutStatus(shortcut: shortcut, binding: binding, state: .failed(status))
        }

        hasConflicts = statuses.contains { status in
            if case .failed = status.state {
                return true
            }
            return false
        }
    }

    private func handler(for shortcut: ScreenshotShortcut) -> () -> Void {
        switch shortcut {
        case .fullScreen:
            return onCaptureFullScreen
        case .selection:
            return onCaptureSelection
        case .captureHUD:
            return onShowCaptureHUD
        }
    }
}
