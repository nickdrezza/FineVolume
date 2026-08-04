import AppKit

final class VolumeHUD {
    private let panel: NSPanel
    private let symbolView: NSImageView
    private let percentageLabel: NSTextField
    private let progressIndicator: NSProgressIndicator
    private var dismissalWorkItem: DispatchWorkItem?

    init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 230, height: 104),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let background = NSVisualEffectView(frame: panel.contentView!.bounds)
        background.autoresizingMask = [.width, .height]
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 18
        background.layer?.masksToBounds = true
        panel.contentView = background

        symbolView = NSImageView()
        symbolView.translatesAutoresizingMaskIntoConstraints = false
        symbolView.contentTintColor = .white
        symbolView.imageScaling = .scaleProportionallyUpOrDown

        percentageLabel = NSTextField(labelWithString: "—%")
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        percentageLabel.textColor = .white
        percentageLabel.font = .monospacedDigitSystemFont(ofSize: 26, weight: .semibold)
        percentageLabel.alignment = .right

        progressIndicator = NSProgressIndicator()
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 100
        progressIndicator.controlTint = .blueControlTint

        background.addSubview(symbolView)
        background.addSubview(percentageLabel)
        background.addSubview(progressIndicator)

        NSLayoutConstraint.activate([
            symbolView.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 24),
            symbolView.topAnchor.constraint(equalTo: background.topAnchor, constant: 20),
            symbolView.widthAnchor.constraint(equalToConstant: 34),
            symbolView.heightAnchor.constraint(equalToConstant: 34),

            percentageLabel.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -24),
            percentageLabel.centerYAnchor.constraint(equalTo: symbolView.centerYAnchor),

            progressIndicator.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 24),
            progressIndicator.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -24),
            progressIndicator.topAnchor.constraint(equalTo: symbolView.bottomAnchor, constant: 16),
            progressIndicator.heightAnchor.constraint(equalToConstant: 8),
        ])
    }

    func show(volume: Float) {
        let percent = Int((volume * 100).rounded())
        percentageLabel.stringValue = "\(percent)%"
        progressIndicator.doubleValue = Double(percent)
        symbolView.image = NSImage(
            systemSymbolName: symbolName(for: percent),
            accessibilityDescription: "Volume \(percent) percent"
        )

        positionOnActiveScreen()
        dismissalWorkItem?.cancel()
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                self.panel.animator().alphaValue = 0
            } completionHandler: {
                self.panel.orderOut(nil)
            }
        }
        dismissalWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1, execute: workItem)
    }

    private func positionOnActiveScreen() {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }

        let origin = NSPoint(
            x: visibleFrame.midX - panel.frame.width / 2,
            y: visibleFrame.minY + 90
        )
        panel.setFrameOrigin(origin)
    }

    private func symbolName(for percent: Int) -> String {
        switch percent {
        case 0:
            return "speaker.slash.fill"
        case 1...33:
            return "speaker.wave.1.fill"
        case 34...66:
            return "speaker.wave.2.fill"
        default:
            return "speaker.wave.3.fill"
        }
    }
}
