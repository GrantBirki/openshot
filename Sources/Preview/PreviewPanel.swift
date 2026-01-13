import AppKit

final class PreviewPanel: NSPanel {
    private let content: PreviewContentView

    init(image: NSImage, onClose: @escaping () -> Void, onTrash: @escaping () -> Void) {
        let size = PreviewPanel.preferredSize(for: image)
        content = PreviewContentView(frame: NSRect(origin: .zero, size: size))
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .statusBar
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        content.configure(image: image, onClose: onClose, onTrash: onTrash)
        contentView = content
    }

    func show() {
        guard let screen = NSScreen.main else {
            center()
            makeKeyAndOrderFront(nil)
            return
        }

        let padding: CGFloat = 24
        let frame = frameRect(forContentRect: content.bounds)
        let origin = CGPoint(
            x: screen.visibleFrame.maxX - frame.width - padding,
            y: screen.visibleFrame.minY + padding
        )
        setFrameOrigin(origin)
        orderFrontRegardless()
    }

    private static func preferredSize(for image: NSImage) -> NSSize {
        let maxWidth: CGFloat = 320
        let maxHeight: CGFloat = 200
        let imageSize = image.size
        let widthRatio = maxWidth / imageSize.width
        let heightRatio = maxHeight / imageSize.height
        let scale = min(widthRatio, heightRatio, 1)
        return NSSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }
}

final class PreviewContentView: NSView {
    private let imageView = PreviewImageView()
    private let closeButton = NSButton()
    private let trashButton = NSButton()
    private var onClose: (() -> Void)?
    private var onTrash: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.9).cgColor

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        closeButton.bezelStyle = .inline
        closeButton.isBordered = false
        closeButton.target = self
        closeButton.action = #selector(handleClose)
        closeButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Close")
        closeButton.contentTintColor = .secondaryLabelColor
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)

        trashButton.bezelStyle = .inline
        trashButton.isBordered = false
        trashButton.target = self
        trashButton.action = #selector(handleTrash)
        trashButton.image = NSImage(systemSymbolName: "trash.circle.fill", accessibilityDescription: "Trash")
        trashButton.contentTintColor = .systemRed
        trashButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(trashButton)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            closeButton.widthAnchor.constraint(equalToConstant: 18),
            closeButton.heightAnchor.constraint(equalToConstant: 18),

            trashButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            trashButton.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            trashButton.widthAnchor.constraint(equalToConstant: 18),
            trashButton.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func configure(image: NSImage, onClose: @escaping () -> Void, onTrash: @escaping () -> Void) {
        imageView.image = image
        imageView.onOpen = { [weak self] in
            self?.openImage(image)
        }
        self.onClose = onClose
        self.onTrash = onTrash
    }

    private func openImage(_ image: NSImage) {
        let filename = FilenameFormatter.makeFilename(prefix: "screenshot")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            _ = try FileSaveService.save(image: image, to: tempURL.deletingLastPathComponent(), filename: filename)
            NSWorkspace.shared.open(tempURL)
        } catch {
            NSLog("Failed to open preview image: \(error)")
        }
    }

    @objc private func handleClose() {
        onClose?()
    }

    @objc private func handleTrash() {
        onTrash?()
    }
}

final class PreviewImageView: NSImageView, NSDraggingSource {
    var onOpen: (() -> Void)?
    private var didDrag = false
    private var draggingSessionStarted = false

    override func mouseDown(with event: NSEvent) {
        didDrag = false
        draggingSessionStarted = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !draggingSessionStarted, let image = image else { return }
        didDrag = true
        draggingSessionStarted = true

        let draggingItem = NSDraggingItem(pasteboardWriter: image)
        let dragFrame = bounds
        draggingItem.setDraggingFrame(dragFrame, contents: image)
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    override func mouseUp(with event: NSEvent) {
        if !didDrag {
            onOpen?()
        }
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        draggingSessionStarted = false
    }
}
