import AppKit
import FineVolumeCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let volumeController = SystemVolumeController(step: 0.01)
    private var hotKeyManager: HotKeyManager?
    private var statusItem: NSStatusItem?
    private var currentVolumeItem: NSMenuItem?
    private var enabledItem: NSMenuItem?
    private var errorItem: NSMenuItem?
    private var isEnabled = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        enableShortcuts()
        refreshVolumeDisplay()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshVolumeDisplay()
    }

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        enabledItem?.state = isEnabled ? .on : .off

        if isEnabled {
            enableShortcuts()
        } else {
            hotKeyManager?.stop()
            clearError()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "speaker.wave.2.fill",
                accessibilityDescription: "Fine Volume"
            )
        }

        let menu = NSMenu()
        menu.delegate = self

        let titleItem = NSMenuItem(title: "Fine Volume", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        let currentVolumeItem = NSMenuItem(title: "Volume: —", action: nil, keyEquivalent: "")
        currentVolumeItem.isEnabled = false
        menu.addItem(currentVolumeItem)
        self.currentVolumeItem = currentVolumeItem

        menu.addItem(.separator())

        let enabledItem = NSMenuItem(
            title: "Enable 1% shortcuts",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enabledItem.target = self
        enabledItem.state = .on
        menu.addItem(enabledItem)
        self.enabledItem = enabledItem

        let shortcutItem = NSMenuItem(
            title: "⌃⌥↑ / ⌃⌥↓  ·  1%",
            action: nil,
            keyEquivalent: ""
        )
        shortcutItem.isEnabled = false
        menu.addItem(shortcutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Fine Volume",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        self.statusItem = statusItem
    }

    private func enableShortcuts() {
        let manager = HotKeyManager { [weak self] hotKey in
            self?.handle(hotKey)
        }

        do {
            try manager.start()
            hotKeyManager = manager
            clearError()
        } catch {
            hotKeyManager = nil
            showError(error.localizedDescription)
        }
    }

    private func handle(_ hotKey: FineVolumeHotKey) {
        let direction: VolumeDirection = hotKey == .volumeUp ? .up : .down

        do {
            let volume = try volumeController.adjust(direction)
            updateVolumeDisplay(volume)
            clearError()
        } catch {
            showError(error.localizedDescription)
            refreshVolumeDisplay()
        }
    }

    private func refreshVolumeDisplay() {
        do {
            updateVolumeDisplay(try volumeController.currentVolume())
        } catch {
            currentVolumeItem?.title = "Volume: unavailable"
            showError(error.localizedDescription)
        }
    }

    private func updateVolumeDisplay(_ volume: Float) {
        let percent = Int((volume * 100).rounded())
        currentVolumeItem?.title = "Volume: \(percent)%"
    }

    private func showError(_ message: String) {
        guard let menu = statusItem?.menu else { return }

        if errorItem == nil {
            let item = NSMenuItem(title: message, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.insertItem(item, at: max(menu.numberOfItems - 2, 0))
            errorItem = item
        } else {
            errorItem?.title = message
        }
    }

    private func clearError() {
        guard let errorItem, let menu = statusItem?.menu else { return }
        menu.removeItem(errorItem)
        self.errorItem = nil
    }
}
