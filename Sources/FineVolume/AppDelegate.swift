import AppKit
import FineVolumeCore
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let completedOnboardingKey = "completedFirstLaunchOnboarding"

    private let volumeController = SystemVolumeController(step: 0.01)
    private let launchAtLoginManager = LaunchAtLoginManager()
    private var hotKeyManager: HotKeyManager?
    private var statusItem: NSStatusItem?
    private var currentVolumeItem: NSMenuItem?
    private var enabledItem: NSMenuItem?
    private var launchAtLoginItem: NSMenuItem?
    private var errorItem: NSMenuItem?
    private var isEnabled = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        enableShortcuts()
        refreshVolumeDisplay()
        refreshLaunchAtLoginDisplay()
        showFirstLaunchOnboardingIfNeeded()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshVolumeDisplay()
        refreshLaunchAtLoginDisplay()
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

    @objc private func toggleLaunchAtLogin() {
        do {
            switch launchAtLoginManager.status {
            case .enabled:
                try launchAtLoginManager.disable()
            case .requiresApproval:
                launchAtLoginManager.openSystemSettings()
            case .notRegistered, .notFound:
                try launchAtLoginManager.enable()
                showLoginApprovalIfNeeded()
            @unknown default:
                break
            }
            refreshLaunchAtLoginDisplay()
        } catch {
            showModalError(
                title: "Couldn’t Change Login Setting",
                message: error.localizedDescription
            )
        }
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

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)
        self.launchAtLoginItem = launchAtLoginItem

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

    private func showFirstLaunchOnboardingIfNeeded() {
        guard ProcessInfo.processInfo.environment["FINEVOLUME_SKIP_ONBOARDING"] != "1" else {
            return
        }

        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.completedOnboardingKey) else { return }

        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Welcome to Fine Volume"
        alert.informativeText = """
        Use Control + Option + Up Arrow or Down Arrow to change your Mac’s volume in 1% steps.

        Fine Volume does not need Accessibility, Input Monitoring, microphone, or audio-recording permission.

        Would you like Fine Volume to start automatically when you log in?
        """
        alert.addButton(withTitle: "Launch at Login")
        alert.addButton(withTitle: "Not Now")

        let response = alert.runModal()
        defaults.set(true, forKey: Self.completedOnboardingKey)

        guard response == .alertFirstButtonReturn else { return }

        do {
            try launchAtLoginManager.enable()
            refreshLaunchAtLoginDisplay()
            showLoginApprovalIfNeeded()
        } catch {
            showModalError(
                title: "Couldn’t Enable Launch at Login",
                message: error.localizedDescription
            )
        }
    }

    private func showLoginApprovalIfNeeded() {
        guard launchAtLoginManager.status == .requiresApproval else { return }

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Approve Launch at Login"
        alert.informativeText = "macOS needs your approval in System Settings → General → Login Items."
        alert.addButton(withTitle: "Open Login Items")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            launchAtLoginManager.openSystemSettings()
        }
    }

    private func refreshLaunchAtLoginDisplay() {
        guard let launchAtLoginItem else { return }

        switch launchAtLoginManager.status {
        case .enabled:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .on
        case .requiresApproval:
            launchAtLoginItem.title = "Launch at Login — Approval Required"
            launchAtLoginItem.state = .mixed
        case .notRegistered:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .off
        case .notFound:
            launchAtLoginItem.title = "Launch at Login — Unavailable"
            launchAtLoginItem.state = .off
        @unknown default:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .off
        }
    }

    private func showModalError(title: String, message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
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
