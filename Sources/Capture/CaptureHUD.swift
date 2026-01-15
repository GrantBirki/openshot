import AppKit

final class CaptureHUDController {
    private enum Layout {
        static let size = NSSize(width: 360, height: 80)
        static let padding: CGFloat = 16
    }

    private let onCaptureSelection: () -> Void
    private let onCaptureWindow: () -> Void
    private let onCaptureFullScreen: () -> Void
    private var panel: NSPanel?

    init(
        onCaptureSelection: @escaping () -> Void,
        onCaptureWindow: @escaping () -> Void,
        onCaptureFullScreen: @escaping () -> Void
    ) {
        self.onCaptureSelection = onCaptureSelection
        self.onCaptureWindow = onCaptureWindow
        self.onCaptureFullScreen = onCaptureFullScreen
    }

    func show() {
        let panel = panel ?? makePanel()
        position(panel: panel)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(panel.contentView)
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Layout.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let content = CaptureHUDView(
            frame: NSRect(origin: .zero, size: Layout.size),
            onCaptureSelection: { [weak self] in
                self?.hide()
                self?.onCaptureSelection()
            },
            onCaptureWindow: { [weak self] in
                self?.hide()
                self?.onCaptureWindow()
            },
            onCaptureFullScreen: { [weak self] in
                self?.hide()
                self?.onCaptureFullScreen()
            },
            onCancel: { [weak self] in
                self?.hide()
            }
        )
        panel.contentView = content
        return panel
    }

    private func position(panel: NSPanel) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            panel.center()
            return
        }

        let frame = panel.frame
        let screenFrame = screen.visibleFrame
        let origin = CGPoint(
            x: screenFrame.midX - frame.width / 2,
            y: screenFrame.maxY - frame.height - Layout.padding
        )
        panel.setFrame(NSRect(origin: origin, size: frame.size), display: false)
    }
}

final class CaptureHUDView: NSView {
    private enum Layout {
        static let cornerRadius: CGFloat = 12
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 10
        static let buttonHeight: CGFloat = 28
    }

    private let backgroundView = NSVisualEffectView()
    private let stackView = NSStackView()
    private let onCaptureSelection: () -> Void
    private let onCaptureWindow: () -> Void
    private let onCaptureFullScreen: () -> Void
    private let onCancel: () -> Void

    init(
        frame frameRect: NSRect,
        onCaptureSelection: @escaping () -> Void,
        onCaptureWindow: @escaping () -> Void,
        onCaptureFullScreen: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onCaptureSelection = onCaptureSelection
        self.onCaptureWindow = onCaptureWindow
        self.onCaptureFullScreen = onCaptureFullScreen
        self.onCancel = onCancel
        super.init(frame: frameRect)

        backgroundView.material = .hudWindow
        backgroundView.blendingMode = .withinWindow
        backgroundView.state = .active
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = Layout.cornerRadius
        backgroundView.layer?.masksToBounds = true
        addSubview(backgroundView)

        stackView.orientation = .horizontal
        stackView.spacing = 8
        stackView.alignment = .centerY
        stackView.distribution = .fillEqually
        backgroundView.addSubview(stackView)

        stackView.addArrangedSubview(makeButton(title: "Selection", action: #selector(handleSelection)))
        stackView.addArrangedSubview(makeButton(title: "Window", action: #selector(handleWindow)))
        stackView.addArrangedSubview(makeButton(title: "Full Screen", action: #selector(handleFullScreen)))
    }

    required init?(coder _: NSCoder) {
        nil
    }

    override var acceptsFirstResponder: Bool { true }

    override func layout() {
        super.layout()
        backgroundView.frame = bounds
        let inset = NSEdgeInsets(
            top: Layout.verticalPadding,
            left: Layout.horizontalPadding,
            bottom: Layout.verticalPadding,
            right: Layout.horizontalPadding
        )
        stackView.frame = bounds.inset(by: inset)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel()
        }
    }

    @objc private func handleSelection() {
        onCaptureSelection()
    }

    @objc private func handleWindow() {
        onCaptureWindow()
    }

    @objc private func handleFullScreen() {
        onCaptureFullScreen()
    }

    private func makeButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: Layout.buttonHeight).isActive = true
        return button
    }
}
