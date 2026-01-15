import AppKit

final class PreviewPanel: NSPanel {
    private let content: PreviewContentView
    private enum Layout {
        static let padding: CGFloat = 16
        static let desiredPixelSize = CGSize(width: 600, height: 500)
    }

    init(
        image: NSImage,
        pngData: Data,
        filenamePrefix: String,
        onClose: @escaping () -> Void,
        onTrash: @escaping () -> Void
    ) {
        let size = PreviewPanel.defaultSize()
        content = PreviewContentView(frame: NSRect(origin: .zero, size: size))
        content.autoresizingMask = [.width, .height]
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

        content.configure(
            image: image,
            pngData: pngData,
            filenamePrefix: filenamePrefix,
            onClose: onClose,
            onTrash: onTrash
        )
        contentView = content
    }

    override var canBecomeKey: Bool {
        true
    }

    func show(on screen: NSScreen?) {
        guard let screen = screen ?? PreviewPanel.targetScreen() else {
            center()
            makeKeyAndOrderFront(nil)
            return
        }

        let safeFrame = PreviewPanel.safeFrame(for: screen)
        let padding = Layout.padding
        let availableSize = NSSize(
            width: max(safeFrame.width - padding * 2, 1),
            height: max(safeFrame.height - padding * 2, 1)
        )
        let desiredSize = PreviewPanel.desiredSize(for: screen)
        let targetSize = NSSize(
            width: min(desiredSize.width, availableSize.width),
            height: min(desiredSize.height, availableSize.height)
        )
        let contentRect = NSRect(origin: .zero, size: targetSize)
        content.frame = contentRect
        setContentSize(targetSize)

        let frame = frameRect(forContentRect: contentRect)
        var origin = CGPoint(
            x: safeFrame.maxX - frame.width - padding,
            y: safeFrame.minY + padding
        )

        let minX = safeFrame.minX + padding
        let maxX = safeFrame.maxX - frame.width - padding
        let minY = safeFrame.minY + padding
        let maxY = safeFrame.maxY - frame.height - padding

        origin.x = maxX < minX ? minX : min(max(origin.x, minX), maxX)
        origin.y = maxY < minY ? minY : min(max(origin.y, minY), maxY)

        contentMinSize = targetSize
        contentMaxSize = targetSize
        minSize = frame.size
        maxSize = frame.size

        let targetFrame = NSRect(origin: origin, size: frame.size)
        setFrame(targetFrame, display: false)
        makeKeyAndOrderFront(nil)
        // AppKit can apply intrinsic sizing on first display; re-apply the fixed frame.
        setFrame(targetFrame, display: false)
        makeFirstResponder(content)
    }

    private static func desiredSize(for screen: NSScreen) -> NSSize {
        let rect = NSRect(origin: .zero, size: Layout.desiredPixelSize)
        return screen.convertRectFromBacking(rect).size
    }

    private static func defaultSize() -> NSSize {
        if let screen = NSScreen.main {
            return desiredSize(for: screen)
        }
        return NSSize(
            width: Layout.desiredPixelSize.width,
            height: Layout.desiredPixelSize.height
        )
    }

    static func screen(for rect: CGRect?) -> NSScreen? {
        guard let rect = rect else {
            return targetScreen()
        }

        let screens = NSScreen.screens
        guard !screens.isEmpty else { return nil }

        let best = screens.max { lhs, rhs in
            rect.intersection(lhs.frame).area < rect.intersection(rhs.frame).area
        }

        if let best = best, rect.intersection(best.frame).area > 0 {
            return best
        }

        return targetScreen()
    }

    private static func targetScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) {
            return screen
        }
        return NSScreen.main ?? NSScreen.screens.first
    }

    private static func safeFrame(for screen: NSScreen) -> CGRect {
        let visible = screen.visibleFrame
        if visible.width > 0, visible.height > 0 {
            return visible
        }
        return screen.frame
    }
}

private extension CGRect {
    var area: CGFloat {
        guard !isNull else { return 0 }
        return width * height
    }
}

final class PreviewContentView: NSView {
    private enum Layout {
        static let cornerRadius: CGFloat = 12
        static let buttonSize: CGFloat = 22
        static let buttonInset: CGFloat = 8
        static let hoverScale: CGFloat = 0.95
        static let hoverAnimationDuration: TimeInterval = 0.12
    }

    private static let tempFileCleanupDelay: TimeInterval = 60

    private let backgroundView = NSVisualEffectView()
    private let imageView = NSImageView()
    private let closeButton = PreviewActionButton(
        symbolName: "xmark",
        baseColor: NSColor.systemGray.withAlphaComponent(0.35),
        hoverColor: NSColor.systemGray.withAlphaComponent(0.55),
        tintColor: .labelColor,
        accessibilityLabel: "Dismiss preview",
        identifier: "preview-close"
    )
    private let trashButton = PreviewActionButton(
        symbolName: "trash",
        baseColor: NSColor.systemRed.withAlphaComponent(0.75),
        hoverColor: .systemRed,
        tintColor: .white,
        accessibilityLabel: "Delete screenshot",
        identifier: "preview-trash"
    )
    private var dragPayload: PreviewDragPayload?
    private var onClose: (() -> Void)?
    private var onTrash: (() -> Void)?
    private var trackingArea: NSTrackingArea?
    private var hoverHideWorkItem: DispatchWorkItem?
    private var didDrag = false
    private var draggingSessionStarted = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        backgroundView.material = .hudWindow
        backgroundView.blendingMode = .withinWindow
        backgroundView.state = .active
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = Layout.cornerRadius
        backgroundView.layer?.masksToBounds = true
        addSubview(backgroundView)

        imageView.imageScaling = .scaleProportionallyUpOrDown
        backgroundView.addSubview(imageView)

        closeButton.target = self
        closeButton.action = #selector(handleClose)
        addSubview(closeButton)

        trashButton.target = self
        trashButton.action = #selector(handleTrash)
        addSubview(trashButton)

        setButtonsVisible(false, animated: false)
    }

    required init?(coder _: NSCoder) {
        return nil
    }

    override func layout() {
        super.layout()
        backgroundView.frame = bounds
        imageView.frame = backgroundView.bounds
        let buttonSize = Layout.buttonSize
        let buttonInset = Layout.buttonInset
        let buttonOriginY = bounds.height - buttonSize - buttonInset
        closeButton.frame = NSRect(
            x: buttonInset,
            y: buttonOriginY,
            width: buttonSize,
            height: buttonSize
        )
        trashButton.frame = NSRect(
            x: bounds.width - buttonSize - buttonInset,
            y: buttonOriginY,
            width: buttonSize,
            height: buttonSize
        )
    }

    func configure(
        image: NSImage,
        pngData: Data,
        filenamePrefix: String,
        onClose: @escaping () -> Void,
        onTrash: @escaping () -> Void
    ) {
        imageView.image = image
        let payload = PreviewDragPayload(
            image: image,
            pngData: pngData,
            filenamePrefix: filenamePrefix
        )
        dragPayload = payload
        self.onClose = onClose
        self.onTrash = onTrash
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with _: NSEvent) {
        setButtonsVisible(true, animated: true)
    }

    override func mouseExited(with _: NSEvent) {
        setButtonsVisible(false, animated: true)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if !closeButton.isHidden, closeButton.frame.contains(point) {
            return closeButton
        }
        if !trashButton.isHidden, trashButton.frame.contains(point) {
            return trashButton
        }
        return self
    }

    override func mouseDown(with event: NSEvent) {
        if isActionButtonEvent(event) {
            return
        }
        didDrag = false
        draggingSessionStarted = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !isActionButtonEvent(event) else { return }
        guard !draggingSessionStarted, let payload = dragPayload else { return }
        guard let draggingItem = payload.makeDraggingItem(dragFrame: bounds) else { return }
        didDrag = true
        draggingSessionStarted = true

        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    override func mouseUp(with event: NSEvent) {
        if isActionButtonEvent(event) {
            return
        }
        if !didDrag, let image = imageView.image {
            openImage(image)
        }
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onClose?()
            return
        }
        if event.modifierFlags.contains(.command), event.keyCode == 51 {
            onTrash?()
            return
        }
        super.keyDown(with: event)
    }

    private func isActionButtonEvent(_ event: NSEvent) -> Bool {
        let point = convert(event.locationInWindow, from: nil)
        if !closeButton.isHidden, closeButton.frame.contains(point) {
            return true
        }
        if !trashButton.isHidden, trashButton.frame.contains(point) {
            return true
        }
        return false
    }

    private func openImage(_ image: NSImage) {
        let filename = FilenameFormatter.makeFilename(prefix: "screenshot")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            _ = try FileSaveService.save(image: image, to: tempURL.deletingLastPathComponent(), filename: filename)
            let opened = NSWorkspace.shared.open(tempURL)
            if !opened {
                NSLog("Failed to open preview image at \(tempURL.path)")
            }
            scheduleTempCleanup(for: tempURL)
        } catch {
            NSLog("Failed to open preview image: \(error)")
        }
    }

    private func scheduleTempCleanup(for url: URL) {
        let delay = PreviewContentView.tempFileCleanupDelay
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    @objc private func handleClose() {
        onClose?()
    }

    @objc private func handleTrash() {
        onTrash?()
    }
    private func setButtonsVisible(_ visible: Bool, animated: Bool) {
        hoverHideWorkItem?.cancel()
        let targetAlpha: CGFloat = visible ? 1 : 0
        let targetScale: CGFloat = visible ? 1 : Layout.hoverScale
        if visible {
            closeButton.isHidden = false
            trashButton.isHidden = false
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Layout.hoverAnimationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                closeButton.animator().alphaValue = targetAlpha
                trashButton.animator().alphaValue = targetAlpha
            }
            CATransaction.begin()
            CATransaction.setAnimationDuration(Layout.hoverAnimationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            closeButton.layer?.transform = CATransform3DMakeScale(targetScale, targetScale, 1)
            trashButton.layer?.transform = CATransform3DMakeScale(targetScale, targetScale, 1)
            CATransaction.commit()
        } else {
            closeButton.alphaValue = targetAlpha
            trashButton.alphaValue = targetAlpha
            closeButton.layer?.transform = CATransform3DMakeScale(targetScale, targetScale, 1)
            trashButton.layer?.transform = CATransform3DMakeScale(targetScale, targetScale, 1)
        }

        if !visible {
            let workItem = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.closeButton.isHidden = true
                self.trashButton.isHidden = true
            }
            hoverHideWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + Layout.hoverAnimationDuration, execute: workItem)
        }
    }
}

extension PreviewContentView: NSDraggingSource {
    func draggingSession(_: NSDraggingSession, sourceOperationMaskFor _: NSDraggingContext) -> NSDragOperation {
        return .copy
    }

    func draggingSession(_: NSDraggingSession, endedAt _: NSPoint, operation _: NSDragOperation) {
        draggingSessionStarted = false
        dragPayload?.rescheduleCleanup()
    }
}

final class PreviewActionButton: NSButton {
    private let baseColor: NSColor
    private let hoverColor: NSColor
    private var trackingArea: NSTrackingArea?

    init(
        symbolName: String,
        baseColor: NSColor,
        hoverColor: NSColor,
        tintColor: NSColor,
        accessibilityLabel: String,
        identifier: String
    ) {
        self.baseColor = baseColor
        self.hoverColor = hoverColor
        super.init(frame: .zero)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel)
        image?.isTemplate = true
        self.image = image
        self.title = ""
        self.contentTintColor = tintColor
        imagePosition = .imageOnly
        bezelStyle = .shadowlessSquare
        isBordered = false
        focusRingType = .none
        wantsLayer = true
        layer?.backgroundColor = baseColor.cgColor
        layer?.masksToBounds = true
        setAccessibilityLabel(accessibilityLabel)
        self.identifier = NSUserInterfaceItemIdentifier(identifier)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func layout() {
        super.layout()
        layer?.cornerRadius = bounds.width / 2
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with _: NSEvent) {
        layer?.backgroundColor = hoverColor.cgColor
    }

    override func mouseExited(with _: NSEvent) {
        layer?.backgroundColor = baseColor.cgColor
    }
}
