import AppKit
import CoreGraphics
import IOKit

enum FineVolumeMediaKey {
    case volumeUp
    case volumeDown
}

enum MediaKeyManagerError: LocalizedError {
    case permissionRequired
    case eventTapUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionRequired:
            return "Allow Accessibility and Input Monitoring to use Control-Option-Volume."
        case .eventTapUnavailable:
            return "Fine Volume could not listen for the volume keys."
        }
    }
}

final class MediaKeyManager {
    typealias Handler = (FineVolumeMediaKey) -> Void

    private let handler: Handler
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    deinit {
        stop()
    }

    func start() throws {
        guard eventTap == nil else { return }
        guard MediaKeyPermissionManager.isAuthorized else {
            throw MediaKeyManagerError.permissionRequired
        }

        let eventMask = CGEventMask(1) << UInt64(NX_SYSDEFINED)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: fineVolumeMediaKeyCallback,
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
    }

    func stop() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
    }

    fileprivate func handle(_ mediaKey: FineVolumeMediaKey) {
        handler(mediaKey)
    }

    fileprivate func reenableTap() {
        guard let eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    fileprivate func isFineVolumeShortcut(_ event: CGEvent) -> Bool {
        let flags = event.flags.union(CGEventSource.flagsState(.combinedSessionState))
        return flags.contains(.maskControl) && flags.contains(.maskAlternate)
    }
}

private let fineVolumeMediaKeyCallback: CGEventTapCallBack = { _, type, event, userData in
    guard let userData else { return Unmanaged.passUnretained(event) }

    let manager = Unmanaged<MediaKeyManager>.fromOpaque(userData).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        manager.reenableTap()
        return Unmanaged.passUnretained(event)
    }

    guard type.rawValue == NX_SYSDEFINED,
          let systemEvent = NSEvent(cgEvent: event),
          systemEvent.subtype.rawValue == Int(NX_SUBTYPE_AUX_CONTROL_BUTTONS)
    else {
        return Unmanaged.passUnretained(event)
    }

    let data1 = UInt32(truncatingIfNeeded: systemEvent.data1)
    let keyCode = Int((data1 >> 16) & 0xFFFF)

    guard keyCode == NX_KEYTYPE_SOUND_UP || keyCode == NX_KEYTYPE_SOUND_DOWN,
          manager.isFineVolumeShortcut(event)
    else {
        return Unmanaged.passUnretained(event)
    }

    let keyState = UInt16(truncatingIfNeeded: data1)
    let isKeyDown = ((keyState >> 8) & 0xFF) == 0xA
    if isKeyDown {
        manager.handle(keyCode == NX_KEYTYPE_SOUND_UP ? .volumeUp : .volumeDown)
    }

    return nil
}
