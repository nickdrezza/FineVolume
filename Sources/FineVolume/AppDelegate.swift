import AppKit
import FineVolumeCore
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let completedOnboardingKey = "completedHIDRemapOnboardingV5"
    private let volumeController = SystemVolumeController(step: 0.01)
    private let launchAtLoginManager = LaunchAtLoginManager()
    private let volumeHUD = VolumeHUD()
    private var mediaKeyManager: MediaKeyManager?
    private var hotKeyManager: HotKeyManager?
    private var permissionTimer: Timer?
    private var statusItem: NSStatusItem?
    private var upShortcutItem: NSMenuItem?
    private var downShortcutItem: NSMenuItem?
    private var launchAtLoginItem: NSMenuItem?
    #if DEBUG
    private var previewWindow: NSWindow?
    #endif

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        refreshLaunchAtLoginDisplay()
        #if DEBUG
        if CommandLine.arguments.contains("--preview") {
            showPreview()
            return
        }
        #endif
        enableShortcuts()
        refreshVolumeDisplay()
        showFirstLaunchOnboardingIfNeeded()
        startPermissionMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionTimer?.invalidate()
        mediaKeyManager?.stop()
        hotKeyManager?.stop()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshLaunchAtLoginDisplay()
        #if DEBUG
        if previewWindow != nil { return }
        #endif
        enableShortcuts()
        refreshVolumeDisplay()
    }

    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func toggleLaunchAtLogin() {
        do {
            switch launchAtLoginManager.status {
            case .enabled:
                try launchAtLoginManager.disable()
            case .requiresApproval:
                launchAtLoginManager.openSystemSettings()
            case .notRegistered, .notFound:
                try launchAtLoginManager.enable()
                if launchAtLoginManager.status == .requiresApproval {
                    launchAtLoginManager.openSystemSettings()
                }
            @unknown default:
                break
            }
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Could not change the login setting"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        refreshLaunchAtLoginDisplay()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "speaker.wave.2.fill", accessibilityDescription: "Fine Volume"
        )
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        upShortcutItem = menu.addItem(withTitle: "⌃ + Volume Up   +1%", action: nil, keyEquivalent: "")
        downShortcutItem = menu.addItem(withTitle: "⌃ + Volume Down   −1%", action: nil, keyEquivalent: "")
        upShortcutItem?.isEnabled = false
        downShortcutItem?.isEnabled = false
        menu.addItem(.separator())
        let login = menu.addItem(withTitle: "Open at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        login.target = self
        launchAtLoginItem = login
        let quit = menu.addItem(withTitle: "Quit Fine Volume", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        item.menu = menu
        statusItem = item
    }

    private func showFirstLaunchOnboardingIfNeeded() {
        guard ProcessInfo.processInfo.environment["FINEVOLUME_SKIP_ONBOARDING"] != "1" else { return }
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.completedOnboardingKey) else { return }
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Volume in 1% steps"
        alert.informativeText = "Allow Input Monitoring to use Control + Volume Up/Down.\nWithout it, use ⌃⌥⌘⇧ + ↑/↓."
        alert.addButton(withTitle: "Open Permissions")
        alert.addButton(withTitle: "Later")
        let response = alert.runModal()
        defaults.set(true, forKey: Self.completedOnboardingKey)
        if response == .alertFirstButtonReturn {
            MediaKeyPermissionManager.requestAccess()
            if !MediaKeyPermissionManager.isAuthorized {
                MediaKeyPermissionManager.openPrivacySettings()
            }
            enableShortcuts()
        }
    }

    private func refreshLaunchAtLoginDisplay() {
        guard let item = launchAtLoginItem else { return }
        item.title = "Open at Login"
        item.isEnabled = true
        switch launchAtLoginManager.status {
        case .enabled:
            item.state = .on
        case .requiresApproval:
            item.title = "Open at Login — Approve in Settings"
            item.state = .mixed
        case .notRegistered:
            item.state = .off
        case .notFound:
            item.title = "Open at Login — Unavailable"
            item.state = .off
            item.isEnabled = false
        @unknown default:
            item.state = .off
            item.isEnabled = false
        }
    }

    private func refreshShortcutDisplay() {
        if hotKeyManager == nil {
            upShortcutItem?.title = "Volume Up — Shortcut unavailable"
            downShortcutItem?.title = "Volume Down — Shortcut unavailable"
        } else if mediaKeyManager != nil {
            upShortcutItem?.title = "⌃ + Volume Up   +1%"
            downShortcutItem?.title = "⌃ + Volume Down   −1%"
        } else {
            upShortcutItem?.title = "⌃⌥⌘⇧ + ↑   +1%"
            downShortcutItem?.title = "⌃⌥⌘⇧ + ↓   −1%"
        }
    }

    private func enableShortcuts() {
        defer { refreshShortcutDisplay() }
        if hotKeyManager == nil {
            let manager = HotKeyManager { [weak self] in self?.handle($0) }
            do {
                try manager.start()
                hotKeyManager = manager
            } catch {
                showError(error.localizedDescription)
                return
            }
        }
        guard MediaKeyPermissionManager.isAuthorized else {
            mediaKeyManager?.stop()
            mediaKeyManager = nil
            return
        }
        guard mediaKeyManager == nil else { return }
        do {
            let manager = try MediaKeyManager { [weak self] in self?.showError($0.localizedDescription) }
            try manager.start()
            mediaKeyManager = manager
            permissionTimer?.invalidate()
            permissionTimer = nil
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func startPermissionMonitor() {
        guard permissionTimer == nil, !MediaKeyPermissionManager.isAuthorized else { return }
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.enableShortcuts()
        }
    }

    private func handle(_ hotKey: FineVolumeHotKey) {
        let direction: VolumeDirection = hotKey == .volumeUp ? .up : .down
        do {
            let volume = try volumeController.adjust(direction)
            updateVolumeDisplay(volume)
            volumeHUD.show(volume: volume)
        } catch {
            showError(error.localizedDescription)
            NSSound.beep()
        }
    }

    private func refreshVolumeDisplay() {
        do { updateVolumeDisplay(try volumeController.currentVolume()) }
        catch { showError(error.localizedDescription) }
    }

    private func updateVolumeDisplay(_ volume: Float) {
        let percent = Int((volume * 100).rounded())
        statusItem?.button?.toolTip = "Fine Volume: \(percent)%"
    }

    private func showError(_ message: String) {
        statusItem?.button?.toolTip = message
        NSLog("Fine Volume: %@", message)
    }

    #if DEBUG
    // Show the actual menu without registering hotkeys or requesting permissions.
    private func showPreview() {
        NSApp.setActivationPolicy(.regular)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 360, height: 260),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Fine Volume Preview"
        window.isReleasedWhenClosed = false
        let button = NSButton(title: "Open Fine Volume", target: self, action: #selector(openPreviewMenu))
        button.frame = NSRect(x: 80, y: 195, width: 200, height: 30)
        window.contentView?.addSubview(button)
        window.center()
        window.makeKeyAndOrderFront(nil)
        previewWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openPreviewMenu(_ sender: NSButton) {
        statusItem?.menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
    }
    #endif
}
