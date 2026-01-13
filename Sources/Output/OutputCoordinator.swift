import AppKit

final class OutputCoordinator {
    private let settings: SettingsStore
    private var pendingSaves: [UUID: DispatchWorkItem] = [:]
    private let queue = DispatchQueue(label: "openshot.output", qos: .userInitiated)

    init(settings: SettingsStore) {
        self.settings = settings
    }

    func begin(image: NSImage) -> UUID {
        ClipboardService.copy(image: image)

        let id = UUID()
        let delay = settings.saveDelaySeconds
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSave(image: image, id: id)
        }
        pendingSaves[id] = workItem
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        return id
    }

    func cancel(id: UUID) {
        if let workItem = pendingSaves[id] {
            workItem.cancel()
        }
        pendingSaves.removeValue(forKey: id)
    }

    private func performSave(image: NSImage, id: UUID) {
        guard let workItem = pendingSaves[id], !workItem.isCancelled else {
            pendingSaves.removeValue(forKey: id)
            return
        }

        let directory = SaveLocationResolver.resolve(
            option: settings.saveLocationOption,
            customPath: settings.customSavePath
        )
        let filename = FilenameFormatter.makeFilename(prefix: settings.filenamePrefix)

        do {
            _ = try FileSaveService.save(image: image, to: directory, filename: filename)
        } catch {
            NSLog("Failed to save screenshot: \(error)")
        }

        pendingSaves.removeValue(forKey: id)
    }
}
