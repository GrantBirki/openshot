import SwiftUI
import AppKit

struct PreferencesView: View {
    @ObservedObject var settings: SettingsStore

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
                TextField("Filename prefix", text: $settings.filenamePrefix)

                Picker("Save location", selection: $settings.saveLocationOption) {
                    ForEach(SaveLocationOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }

                if settings.saveLocationOption == .custom {
                    HStack {
                        TextField("Custom folder", text: $settings.customSavePath)
                        Button("Choose...") {
                            chooseFolder()
                        }
                    }
                }

                HStack {
                    Text("Save delay (seconds)")
                    Spacer()
                    TextField("", value: $settings.saveDelaySeconds, formatter: numberFormatter)
                        .frame(width: 60)
                }
            }

            Section("Preview") {
                Toggle("Show floating preview", isOn: $settings.previewEnabled)
                Toggle("Auto-dismiss preview", isOn: $settings.previewTimeoutEnabled)
                    .disabled(!settings.previewEnabled)
                if settings.previewTimeoutEnabled && settings.previewEnabled {
                    HStack {
                        Text("Preview timeout (seconds)")
                        Spacer()
                        TextField("", value: $settings.previewTimeoutSeconds, formatter: numberFormatter)
                            .frame(width: 60)
                    }
                } else if settings.previewEnabled {
                    Text("Preview stays until you close or trash it.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Hotkeys") {
                TextField("Selection hotkey", text: $settings.hotkeySelection)
                TextField("Full screen hotkey", text: $settings.hotkeyFullScreen)
                TextField("Window hotkey", text: $settings.hotkeyWindow)
                Text("Use format like ctrl+p or ctrl+shift+p.").foregroundStyle(.secondary)
            }
        }
        .padding()
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
}
