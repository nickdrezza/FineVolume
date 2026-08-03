import AudioToolbox
import CoreAudio
import Foundation

public enum SystemVolumeError: LocalizedError {
    case noOutputDevice
    case unsupportedDevice
    case propertyNotSettable
    case coreAudio(operation: String, status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .noOutputDevice:
            return "No default audio output device is available."
        case .unsupportedDevice:
            return "The current audio output does not expose a controllable system volume."
        case .propertyNotSettable:
            return "The current audio output volume is read-only."
        case let .coreAudio(operation, status):
            return "Core Audio could not \(operation) (OSStatus \(status))."
        }
    }
}

public final class SystemVolumeController {
    public let step: Float

    public init(step: Float = 0.01) {
        self.step = step
    }

    public func currentVolume() throws -> Float {
        let device = try defaultOutputDevice()
        var address = volumeAddress

        guard AudioObjectHasProperty(device, &address) else {
            throw SystemVolumeError.unsupportedDevice
        }

        var value: Float = 0
        var size = UInt32(MemoryLayout<Float>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value)

        guard status == noErr else {
            throw SystemVolumeError.coreAudio(operation: "read the volume", status: status)
        }

        return min(max(value, 0), 1)
    }

    @discardableResult
    public func adjust(_ direction: VolumeDirection) throws -> Float {
        let current = try currentVolume()
        let next = VolumeMath.adjusted(current, direction: direction, step: step)
        try setVolume(next)
        return next
    }

    public func setVolume(_ volume: Float) throws {
        let device = try defaultOutputDevice()
        var address = volumeAddress

        guard AudioObjectHasProperty(device, &address) else {
            throw SystemVolumeError.unsupportedDevice
        }

        var settable = DarwinBoolean(false)
        let settableStatus = AudioObjectIsPropertySettable(device, &address, &settable)
        guard settableStatus == noErr else {
            throw SystemVolumeError.coreAudio(
                operation: "check whether the volume can be changed",
                status: settableStatus
            )
        }
        guard settable.boolValue else {
            throw SystemVolumeError.propertyNotSettable
        }

        var value = min(max(volume, 0), 1)
        let size = UInt32(MemoryLayout<Float>.size)
        let status = AudioObjectSetPropertyData(device, &address, 0, nil, size, &value)

        guard status == noErr else {
            throw SystemVolumeError.coreAudio(operation: "set the volume", status: status)
        }
    }

    private var volumeAddress: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    private func defaultOutputDevice() throws -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var device = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &device
        )

        guard status == noErr else {
            throw SystemVolumeError.coreAudio(operation: "find the output device", status: status)
        }
        guard device != kAudioObjectUnknown else {
            throw SystemVolumeError.noOutputDevice
        }

        return device
    }
}
