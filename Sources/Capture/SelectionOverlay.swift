import AppKit

final class SelectionOverlayController {
    private var windows: [OverlayWindow] = []
    private var views: [SelectionOverlayView] = []
    private var selectionState: SelectionOverlayState?

    struct SelectionResult {
        let rect: CGRect
        let excludeWindowID: CGWindowID?
    }

    func beginSelection(
        showSelectionCoordinates: Bool,
        overlayMode: SelectionOverlayMode,
        onOverlayModeChanged: ((SelectionOverlayMode) -> Void)? = nil,
        completion: @escaping (SelectionResult?) -> Void,
    ) {
        guard windows.isEmpty else { return }
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            completion(nil)
            return
        }

        var didFinish = false
        let finish: (SelectionResult?) -> Void = { [weak self] result in
            guard let self, !didFinish else { return }
            didFinish = true
            end()
            completion(result)
        }
        let state = SelectionOverlayState(
            showSelectionCoordinates: showSelectionCoordinates,
            overlayMode: overlayMode,
        )
        selectionState = state
        let refreshViews: () -> Void = { [weak self] in
            guard let self else { return }
            views.forEach { $0.needsDisplay = true }
        }

        for screen in screens {
            let window = OverlayWindow(contentRect: screen.frame)
            let view = SelectionOverlayView(frame: window.contentView?.bounds ?? .zero, state: state)
            var windowID: CGWindowID = 0
            view.onSelectionChanged = refreshViews
            view.onOverlayModeChanged = onOverlayModeChanged
            view.onSelection = { rect in
                finish(SelectionResult(rect: rect, excludeWindowID: windowID))
            }
            view.onCancel = {
                finish(nil)
            }
            window.contentView = view
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(view)
            windowID = CGWindowID(window.windowNumber)
            windows.append(window)
            views.append(view)
        }
    }

    private func end() {
        views.forEach { $0.deactivate() }
        for window in windows {
            window.contentView = nil
            window.orderOut(nil)
        }
        windows.removeAll()
        views.removeAll()
        selectionState = nil
    }
}

final class SelectionOverlayState {
    var start: CGPoint?
    var current: CGPoint?
    let showSelectionCoordinates: Bool
    var overlayMode: SelectionOverlayMode
    private var overlayModeHUDMessage: String?
    private var overlayModeHUDExpiresAt: Date?

    init(showSelectionCoordinates: Bool, overlayMode: SelectionOverlayMode = .inverse) {
        self.showSelectionCoordinates = showSelectionCoordinates
        self.overlayMode = overlayMode
    }

    var rect: CGRect? {
        guard let start, let current else { return nil }
        return CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(start.x - current.x),
            height: abs(start.y - current.y),
        )
    }

    var selectionSizeText: String? {
        guard showSelectionCoordinates, let start, let current else { return nil }
        let width = Int(abs(current.x - start.x).rounded())
        let height = Int(abs(current.y - start.y).rounded())
        return "\(width) x \(height)"
    }

    func toggleOverlayMode() {
        overlayMode = overlayMode.next
        showOverlayModeHUD()
    }

    func showOverlayModeHUD() {
        overlayModeHUDMessage = "Overlay: \(overlayMode.title)"
        overlayModeHUDExpiresAt = Date().addingTimeInterval(1)
    }

    func currentOverlayModeHUDText(now: Date = .now) -> String? {
        guard let text = overlayModeHUDMessage, let expiresAt = overlayModeHUDExpiresAt else { return nil }
        if now >= expiresAt {
            overlayModeHUDMessage = nil
            overlayModeHUDExpiresAt = nil
            return nil
        }
        return text
    }
}

final class SelectionOverlayView: NSView {
    var onSelection: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?
    var onSelectionChanged: (() -> Void)?
    var onOverlayModeChanged: ((SelectionOverlayMode) -> Void)?
    private let state: SelectionOverlayState
    private var overlayHUDToken: UUID?
    private var cursorPushed = false

    init(frame frameRect: NSRect, state: SelectionOverlayState) {
        self.state = state
        super.init(frame: frameRect)
    }

    required init?(coder _: NSCoder) {
        nil
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        window?.invalidateCursorRects(for: self)
        pushCrosshairCursor()
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            popCrosshairCursor()
        }
        super.viewWillMove(toWindow: newWindow)
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        let point = convert(event.locationInWindow, from: nil)
        let screenPoint = window.convertPoint(toScreen: point)
        state.start = screenPoint
        state.current = screenPoint
        onSelectionChanged?()
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window else { return }
        let point = convert(event.locationInWindow, from: nil)
        let screenPoint = window.convertPoint(toScreen: point)
        state.current = screenPoint
        onSelectionChanged?()
    }

    override func mouseUp(with event: NSEvent) {
        guard let window else {
            onCancel?()
            return
        }

        let point = convert(event.locationInWindow, from: nil)
        state.current = window.convertPoint(toScreen: point)
        onSelectionChanged?()
        guard let rect = state.rect else {
            onCancel?()
            return
        }

        if rect.width < 2 || rect.height < 2 {
            onCancel?()
        } else {
            onSelection?(rect)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        } else if event.keyCode == 48 {
            toggleOverlayMode()
        }
    }

    override func cancelOperation(_: Any?) {
        onCancel?()
    }

    override func draw(_: NSRect) {
        drawSelectionOverlay()
        drawSelectionOutline()
        drawSelectionMetrics()
        drawOverlayModeHUD()
    }

    private func drawSelectionOverlay() {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let selection = selectionRect()

        switch state.overlayMode {
        case .macosNativeLike:
            guard let selection else { return }
            context.setFillColor(NSColor.black.withAlphaComponent(0.28).cgColor)
            context.fill(selection)
        case .inverse:
            context.setFillColor(NSColor.black.withAlphaComponent(0.18).cgColor)
            if let selection {
                let path = CGMutablePath()
                path.addRect(bounds)
                path.addRect(selection)
                context.addPath(path)
                context.drawPath(using: .eoFill)
            } else {
                context.fill(bounds)
            }
        }
    }

    private func drawSelectionOutline() {
        guard let selection = selectionRect() else { return }

        NSColor(calibratedWhite: 0.92, alpha: 1).setStroke()
        let path = NSBezierPath(rect: selection)
        path.lineWidth = 1
        path.stroke()
    }

    private func drawSelectionMetrics() {
        guard let window,
              let current = state.current,
              let text = state.selectionSizeText
        else { return }

        let anchor = window.convertPoint(fromScreen: current)
        guard bounds.contains(anchor) else { return }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        let padding = CGSize(width: 6, height: 4)
        let offset = CGPoint(x: 12, y: 12)
        var bubbleRect = CGRect(
            x: anchor.x + offset.x,
            y: anchor.y + offset.y,
            width: textSize.width + padding.width * 2,
            height: textSize.height + padding.height * 2,
        )
        bubbleRect = clamp(bubbleRect, to: bounds, margin: 8)

        NSColor.black.withAlphaComponent(0.75).setFill()
        NSBezierPath(roundedRect: bubbleRect, xRadius: 6, yRadius: 6).fill()
        attributedText.draw(at: CGPoint(x: bubbleRect.minX + padding.width, y: bubbleRect.minY + padding.height))
    }

    private func drawOverlayModeHUD() {
        guard let window,
              let text = state.currentOverlayModeHUDText()
        else { return }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        let padding = CGSize(width: 6, height: 4)
        let offset = CGPoint(x: 12, y: 12)

        let anchor: CGPoint
        if let current = state.current {
            let localPoint = window.convertPoint(fromScreen: current)
            if bounds.contains(localPoint) {
                anchor = localPoint
            } else {
                anchor = CGPoint(x: 12, y: bounds.maxY - 24)
            }
        } else {
            anchor = CGPoint(x: 12, y: bounds.maxY - 24)
        }

        var bubbleRect = CGRect(
            x: anchor.x + offset.x,
            y: anchor.y + offset.y,
            width: textSize.width + padding.width * 2,
            height: textSize.height + padding.height * 2,
        )
        bubbleRect = clamp(bubbleRect, to: bounds, margin: 8)

        NSColor.black.withAlphaComponent(0.75).setFill()
        NSBezierPath(roundedRect: bubbleRect, xRadius: 6, yRadius: 6).fill()
        attributedText.draw(at: CGPoint(x: bubbleRect.minX + padding.width, y: bubbleRect.minY + padding.height))
    }

    private func toggleOverlayMode() {
        state.toggleOverlayMode()
        onOverlayModeChanged?(state.overlayMode)
        onSelectionChanged?()
        scheduleOverlayHUDClear()
    }

    private func scheduleOverlayHUDClear() {
        let token = UUID()
        overlayHUDToken = token
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) { [weak self] in
            guard let self, overlayHUDToken == token else { return }
            onSelectionChanged?()
        }
    }

    func deactivate() {
        popCrosshairCursor()
    }

    private func pushCrosshairCursor() {
        guard !cursorPushed else { return }
        NSCursor.crosshair.push()
        cursorPushed = true
    }

    private func popCrosshairCursor() {
        guard cursorPushed else { return }
        NSCursor.pop()
        cursorPushed = false
    }

    private func clamp(_ rect: CGRect, to bounds: CGRect, margin: CGFloat) -> CGRect {
        var rect = rect
        rect.origin.x = min(max(rect.origin.x, bounds.minX + margin), bounds.maxX - rect.width - margin)
        rect.origin.y = min(max(rect.origin.y, bounds.minY + margin), bounds.maxY - rect.height - margin)
        return rect
    }

    private func selectionRect() -> CGRect? {
        guard let rect = state.rect, let window else { return nil }
        return window.convertFromScreen(rect)
    }
}

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init(contentRect: CGRect) {
        super.init(
            contentRect: contentRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
        )
        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        hasShadow = false
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
}

enum ScreenFrameHelper {
    static func allScreensFrame() -> CGRect? {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return nil }
        return screens.reduce(CGRect.null) { $0.union($1.frame) }
    }
}
