import AppKit
import ApplicationServices
import CoreGraphics

enum MediaKeyPermissionManager {
    static var isAccessibilityAuthorized: Bool {
        AXIsProcessTrusted()
    }

    static var isInputMonitoringAuthorized: Bool {
        CGPreflightListenEventAccess()
    }

    static var isAuthorized: Bool {
        isAccessibilityAuthorized && isInputMonitoringAuthorized
    }

    static func requestAccess() {
        if !isInputMonitoringAuthorized {
            _ = CGRequestListenEventAccess()
        }

        if !isAccessibilityAuthorized {
            let options = [
                kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true,
            ] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
    }

    static func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
