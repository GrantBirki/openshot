import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var shortcutManager: ShortcutManager

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $settings.autoLaunchEnabled)
            }

            Section("Output") {
                LabeledContent("Filename prefix") {
                    TextField("", text: $settings.filenamePrefix)
                        .textFieldStyle(.roundedBorder)
                }

                LabeledContent("Save location") {
                    Picker("", selection: $settings.saveLocationOption) {
                        ForEach(SaveLocationOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .labelsHidden()
                }

                if settings.saveLocationOption == .custom {
                    LabeledContent("Custom folder") {
                        HStack(spacing: 8) {
                            TextField("", text: $settings.customSavePath)
                                .textFieldStyle(.roundedBorder)
                            Button("Choose...") {
                                chooseFolder()
                            }
                        }
                    }
                }
            }

            Section("Preview") {
                Toggle("Show floating preview", isOn: $settings.previewEnabled)
                Toggle("Auto-dismiss preview", isOn: $settings.previewTimeoutEnabled)
                    .disabled(!settings.previewEnabled)
                if settings.previewEnabled {
                    LabeledContent("Save delay (seconds)") {
                        TextField("", value: $settings.saveDelaySeconds, formatter: numberFormatter)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 80)
                    }
                }
                Picker("On new screenshot", selection: $settings.previewReplacementBehavior) {
                    ForEach(PreviewReplacementBehavior.allCases) { behavior in
                        Text(behavior.title)
                            .tag(behavior)
                            .help(behavior.helpText)
                    }
                }
                .disabled(!settings.previewEnabled)
                .help(
                    "Choose what happens to the current preview when a new screenshot is taken " +
                        "and the old preview is still visible."
                )
            }

            Section("Screenshot Shortcuts") {
                Toggle("Use OneShot screenshot shortcuts", isOn: $settings.screenshotShortcutsEnabled)
                    .help("Registers Command+Shift+3/4/5 while OneShot is running.")

                ForEach(shortcutManager.statuses) { status in
                    LabeledContent(status.title) {
                        HStack(spacing: 8) {
                            Text(status.binding)
                                .font(.system(.body, design: .monospaced))
                            Text(status.label)
                                .foregroundStyle(statusColor(for: status.style))
                        }
                    }
                }

                if settings.screenshotShortcutsEnabled, shortcutManager.hasConflicts {
                    Text("Some shortcuts are already in use by macOS.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Enable Shortcuts") {
                // If macOS still owns these keys, we fall back to user instructions instead of event taps.
                Text("Disable macOS screenshot shortcuts to let OneShot handle Command+Shift+3/4/5.")
                Text("System Settings > Keyboard > Keyboard Shortcuts > Screenshots")
                    .foregroundStyle(.secondary)
                Text("Turn off the save/copy shortcuts for the screen and selected area.")
                    .foregroundStyle(.secondary)
                Button("Open Keyboard Shortcuts") {
                    openKeyboardShortcuts()
                }
                Text("Screen Recording permission is required for capture.")
                    .foregroundStyle(.secondary)
                Text("Accessibility or Input Monitoring is only needed if macOS prompts for it.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .background(FocusClearView())
        .padding(20)
        .frame(minWidth: 560, minHeight: 480)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Folder"

        if panel.runModal() == .OK, let url = panel.url {
            settings.customSavePath = url.path
        }
    }

    private func openKeyboardShortcuts() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard?Shortcuts") {
            if NSWorkspace.shared.open(url) {
                return
            }
        }
        if let fallback = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard") {
            _ = NSWorkspace.shared.open(fallback)
        }
    }

    private func statusColor(for style: ShortcutStatusStyle) -> Color {
        switch style {
        case .active:
            return .green
        case .inactive:
            return .secondary
        case .warning:
            return .orange
        }
    }
}

private struct FocusClearView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.attach(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.attach(to: nsView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private weak var view: NSView?
        private var monitor: Any?

        func attach(to view: NSView) {
            self.view = view
            if monitor != nil {
                return
            }

            monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
                guard let self = self,
                      let view = self.view,
                      let window = view.window,
                      window == event.window,
                      let contentView = window.contentView
                else {
                    return event
                }

                let point = contentView.convert(event.locationInWindow, from: nil)
                if let hitView = contentView.hitTest(point), self.isTextInput(view: hitView) {
                    return event
                }

                window.makeFirstResponder(nil)
                return event
            }
        }

        deinit {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
        }

        private func isTextInput(view: NSView) -> Bool {
            if view is NSTextView || view is NSTextField {
                return true
            }

            var current = view.superview
            while let currentView = current {
                if currentView is NSTextField {
                    return true
                }
                current = currentView.superview
            }

            return false
        }
    }
}
