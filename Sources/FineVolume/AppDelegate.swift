import AppKit
import FineVolumeCore
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let completedOnboardingKey = "completedHIDRemapOnboardingV5"
    private static let askedLaunchAtLoginKey = "askedLaunchAtLogin"

    private let volumeController = SystemVolumeController(step: 0.01)
    private let launchAtLoginManager = LaunchAtLoginManager()
    private let volumeHUD = VolumeHUD()
    private var mediaKeyManager: MediaKeyManager?
    private var hotKeyManager: HotKeyManager?
    private var permissionTimer: Timer?
    private var statusItem: NSStatusItem?
    private var currentVolumeItem: NSMenuItem?
    private var enabledItem: NSMenuItem?
    private var mediaKeyAccessItem: NSMenuItem?
    private var launchAtLoginItem: NSMenuItem?
    private var errorItem: NSMenuItem?
    private var isEnabled = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        refreshVolumeDisplay()
        refreshLaunchAtLoginDisplay()
        refreshMediaKeyAccessDisplay()
        showFirstLaunchOnboardingIfNeeded()
        enableShortcuts()
        startPermissionMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionTimer?.invalidate()
        mediaKeyManager?.stop()
        hotKeyManager?.stop()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshVolumeDisplay()
        refreshLaunchAtLoginDisplay()
        refreshMediaKeyAccessDisplay()
        enableShortcuts()
    }

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        enabledItem?.state = isEnabled ? .on : .off

        if isEnabled {
            refreshMediaKeyAccessDisplay()
            enableShortcuts()
        } else {
            mediaKeyManager?.stop()
            mediaKeyManager = nil
            hotKeyManager?.stop()
            hotKeyManager = nil
            clearError()
        }
    }

    @objc private func requestMediaKeyAccess() {
        MediaKeyPermissionManager.requestAccess()
        refreshMediaKeyAccessDisplay()
        enableShortcuts()

        if !MediaKeyPermissionManager.isAuthorized {
            showPrivacySettingsPrompt()
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
            title: "Control + Volume Up / Down  ·  1%",
            action: nil,
            keyEquivalent: ""
        )
        shortcutItem.isEnabled = false
        menu.addItem(shortcutItem)

        let fallbackItem = NSMenuItem(
            title: "Fallback: Hyper (⌃⌥⌘⇧) + ↑ / ↓  ·  1%",
            action: nil,
            keyEquivalent: ""
        )
        fallbackItem.isEnabled = false
        menu.addItem(fallbackItem)

        let mediaKeyAccessItem = NSMenuItem(
            title: "Physical volume keys: Needs Input Monitoring…",
            action: #selector(requestMediaKeyAccess),
            keyEquivalent: ""
        )
        mediaKeyAccessItem.target = self
        menu.addItem(mediaKeyAccessItem)
        self.mediaKeyAccessItem = mediaKeyAccessItem

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
        Hold Control while pressing your Mac’s Volume Up or Volume Down key to change the volume by exactly 1%.

        Fine Volume temporarily remaps only the two volume keys while Control is held. It needs Input Monitoring access to detect the Control key, but does not record audio or inspect what you type.

        A Hyper-key (Control + Option + Command + Shift) plus Up or Down Arrow fallback is available if you would rather not grant that permission.
        """
        alert.addButton(withTitle: "Open Permissions")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        defaults.set(true, forKey: Self.completedOnboardingKey)

        if response == .alertFirstButtonReturn {
            requestMediaKeyAccess()
        }

        showLaunchAtLoginPromptIfNeeded()
    }

    private func showLaunchAtLoginPromptIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.askedLaunchAtLoginKey) else { return }

        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Launch Fine Volume at Login?"
        alert.informativeText = "Fine Volume can be ready whenever you sign in. You can change this later from its menu-bar menu or System Settings."
        alert.addButton(withTitle: "Enable")
        alert.addButton(withTitle: "Not Now")

        let response = alert.runModal()
        defaults.set(true, forKey: Self.askedLaunchAtLoginKey)

        guard response == .alertFirstButtonReturn else { return }

        do {
            try launchAtLoginManager.enable()
            showLoginApprovalIfNeeded()
        } catch {
            showModalError(
                title: "Couldn’t Enable Launch at Login",
                message: error.localizedDescription
            )
        }

        refreshLaunchAtLoginDisplay()
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

    private func showPrivacySettingsPrompt() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Allow Volume-Key Access"
        alert.informativeText = "Enable Fine Volume in System Settings → Privacy & Security → Input Monitoring, then return to Fine Volume. The fallback Hyper-key arrow shortcut remains available without this permission."
        alert.addButton(withTitle: "Open Privacy & Security")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            MediaKeyPermissionManager.openPrivacySettings()
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

    private func refreshMediaKeyAccessDisplay() {
        guard let mediaKeyAccessItem else { return }

        if MediaKeyPermissionManager.isAuthorized {
            mediaKeyAccessItem.title = "Physical volume keys: Ready"
            mediaKeyAccessItem.state = .on
        } else {
            mediaKeyAccessItem.title = "Physical volume keys: Needs Input Monitoring…"
            mediaKeyAccessItem.state = .off
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
        guard isEnabled else { return }

        if hotKeyManager == nil {
            let manager = HotKeyManager { [weak self] hotKey in
                self?.handle(hotKey)
            }

            do {
                try manager.start()
                hotKeyManager = manager
            } catch {
                hotKeyManager = nil
                showError(error.localizedDescription)
            }
        }

        guard MediaKeyPermissionManager.isAuthorized else {
            mediaKeyManager?.stop()
            mediaKeyManager = nil
            return
        }

        guard mediaKeyManager == nil else {
            clearError()
            return
        }

        do {
            let manager = try MediaKeyManager { [weak self] error in
                self?.showError(error.localizedDescription)
            }
            try manager.start()
            mediaKeyManager = manager
            clearError()
            permissionTimer?.invalidate()
            permissionTimer = nil
        } catch {
            mediaKeyManager = nil
            showError(error.localizedDescription)
        }
    }

    private func startPermissionMonitor() {
        guard permissionTimer == nil, !MediaKeyPermissionManager.isAuthorized else { return }

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.refreshMediaKeyAccessDisplay()
            self.enableShortcuts()
        }
    }

    private func handle(_ hotKey: FineVolumeHotKey) {
        let direction: VolumeDirection = hotKey == .volumeUp ? .up : .down

        do {
            let volume = try volumeController.adjust(direction)
            updateVolumeDisplay(volume)
            volumeHUD.show(volume: volume)
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
