import Carbon.HIToolbox
import Foundation

enum FineVolumeHotKey: UInt32 {
    case volumeUp = 1
    case volumeDown = 2
}

enum HotKeyManagerError: LocalizedError {
    case installHandler(OSStatus)
    case registerHotKey(OSStatus)

    var errorDescription: String? {
        switch self {
        case let .installHandler(status):
            return "Fine Volume could not install its shortcut handler (OSStatus \(status))."
        case let .registerHotKey(status):
            return "The shortcut is already in use or could not be registered (OSStatus \(status))."
        }
    }
}

final class HotKeyManager {
    typealias Handler = (FineVolumeHotKey) -> Void

    private static let signature: OSType = 0x46564F4C // "FVOL"
    private let handler: Handler
    private var eventHandler: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef] = []

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    deinit {
        stop()
    }

    func start() throws {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            fineVolumeHotKeyHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard status == noErr else {
            eventHandler = nil
            throw HotKeyManagerError.installHandler(status)
        }

        do {
            try register(.volumeUp, keyCode: UInt32(kVK_UpArrow))
            try register(.volumeDown, keyCode: UInt32(kVK_DownArrow))
        } catch {
            stop()
            throw error
        }
    }

    func stop() {
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    fileprivate func dispatch(id: UInt32) {
        guard let hotKey = FineVolumeHotKey(rawValue: id) else { return }
        handler(hotKey)
    }

    private func register(_ hotKey: FineVolumeHotKey, keyCode: UInt32) throws {
        let id = EventHotKeyID(signature: Self.signature, id: hotKey.rawValue)
        var reference: EventHotKeyRef?
        let modifiers = UInt32(controlKey | optionKey)
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            id,
            GetApplicationEventTarget(),
            0,
            &reference
        )

        guard status == noErr, let reference else {
            throw HotKeyManagerError.registerHotKey(status)
        }
        hotKeyRefs.append(reference)
    }
}

private let fineVolumeHotKeyHandler: EventHandlerUPP = { _, event, userData in
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }

    var id = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &id
    )
    guard status == noErr else { return status }

    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
    manager.dispatch(id: id.id)
    return noErr
}
