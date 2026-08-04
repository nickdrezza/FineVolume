import AppKit
import CoreGraphics

enum MediaKeyPermissionManager {
    static var isInputMonitoringAuthorized: Bool {
        CGPreflightListenEventAccess()
    }

    static var isAuthorized: Bool {
        isInputMonitoringAuthorized
    }

    static func requestAccess() {
        if !isInputMonitoringAuthorized {
            _ = CGRequestListenEventAccess()
        }
    }

    static func openPrivacySettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent",
            "x-apple.systempreferences:com.apple.preference.security",
        ]

        for candidate in candidates {
            guard let url = URL(string: candidate), NSWorkspace.shared.open(url) else {
                continue
            }
            return
        }
    }
}
