import CoreGraphics
import Foundation

enum MediaKeyManagerError: LocalizedError {
    case permissionRequired
    case eventTapUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionRequired:
            return "Enable Input Monitoring for Fine Volume to use Control + Volume Up/Down."
        case .eventTapUnavailable:
            return "Fine Volume could not monitor the Control key."
        }
    }
}

final class MediaKeyManager {
    typealias ErrorHandler = (Error) -> Void

    private let remapper: HIDVolumeKeyRemapper
    private let errorHandler: ErrorHandler
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var watchdogTimer: Timer?
    private var isControlDown = false

    init(errorHandler: @escaping ErrorHandler) throws {
        remapper = try HIDVolumeKeyRemapper()
        self.errorHandler = errorHandler
    }

    deinit {
        stop()
    }

    func start() throws {
        guard eventTap == nil else { return }
        guard MediaKeyPermissionManager.isAuthorized else {
            throw MediaKeyManagerError.permissionRequired
        }

        let eventMask = CGEventMask(1) << CGEventType.flagsChanged.rawValue
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: fineVolumeModifierCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw MediaKeyManagerError.eventTapUnavailable
        }

        guard let runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            eventTap,
            0
        ) else {
            CFMachPortInvalidate(eventTap)
            throw MediaKeyManagerError.eventTapUnavailable
        }

        self.eventTap = eventTap
        self.runLoopSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        updateControlState(
            CGEventSource.flagsState(.combinedSessionState).contains(.maskControl)
        )
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) {
            [weak self] _ in
            self?.updateControlState(
                CGEventSource.flagsState(.combinedSessionState).contains(.maskControl)
            )
        }
    }

    func stop() {
        watchdogTimer?.invalidate()
        watchdogTimer = nil

        if isControlDown {
            try? remapper.setEnabled(false)
            isControlDown = false
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
    }

    fileprivate func handleFlagsChanged(_ event: CGEvent) {
        updateControlState(event.flags.contains(.maskControl))
    }

    fileprivate func reenableTap() {
        guard let eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: true)
        updateControlState(
            CGEventSource.flagsState(.combinedSessionState).contains(.maskControl)
        )
    }

    private func updateControlState(_ controlDown: Bool) {
        guard controlDown != isControlDown else { return }

        do {
            try remapper.setEnabled(controlDown)
            isControlDown = controlDown
        } catch {
            errorHandler(error)
        }
    }
}

private let fineVolumeModifierCallback: CGEventTapCallBack = { _, type, event, userData in
    guard let userData else { return Unmanaged.passUnretained(event) }

    let manager = Unmanaged<MediaKeyManager>.fromOpaque(userData).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        manager.reenableTap()
    } else if type == .flagsChanged {
        manager.handleFlagsChanged(event)
    }

    return Unmanaged.passUnretained(event)
}
