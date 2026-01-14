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

                LabeledContent("Save delay (seconds)") {
                    TextField("", value: $settings.saveDelaySeconds, formatter: numberFormatter)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 80)
                }
            }

            Section("Preview") {
                Toggle("Show floating preview", isOn: $settings.previewEnabled)
                Toggle("Auto-dismiss preview", isOn: $settings.previewTimeoutEnabled)
                    .disabled(!settings.previewEnabled)
                if settings.previewEnabled {
                    Text(settings.previewTimeoutEnabled
                        ? "Auto-dismiss uses the save delay in Output."
                        : "Preview stays until you close or trash it.")
                    .foregroundStyle(.secondary)
                }
            }

            Section("Hotkeys") {
                LabeledContent("Selection") {
                    TextField("", text: $settings.hotkeySelection)
                        .textFieldStyle(.roundedBorder)
                }
                LabeledContent("Full screen") {
                    TextField("", text: $settings.hotkeyFullScreen)
                        .textFieldStyle(.roundedBorder)
                }
                LabeledContent("Window") {
                    TextField("", text: $settings.hotkeyWindow)
                        .textFieldStyle(.roundedBorder)
                }
                Text("Use format like ctrl+p or ctrl+shift+p.")
                    .foregroundStyle(.secondary)
                Text("Some hotkey changes require quitting and reopening OpenShot.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
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
}
